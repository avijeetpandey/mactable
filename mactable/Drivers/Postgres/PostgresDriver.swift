//
//  PostgresDriver.swift
//  mactable
//
//  Native Swift PostgreSQL client (wire protocol v3).
//  Supports: trust, cleartext, MD5 authentication. Simple Query protocol.
//

import Foundation

final class PostgresDriver: DatabaseDriver, @unchecked Sendable {
    let kind: DatabaseKind = .postgres
    private(set) var isConnected: Bool = false
    private(set) var serverVersion: String?

    private var channel: NetworkChannel?
    private var config: ConnectionConfig?
    private var serverParams: [String: String] = [:]
    private let queryGate = AsyncSemaphore(value: 1)

    func connect(config: ConnectionConfig, password: String) async throws {
        let ch = NetworkChannel(host: config.host, port: config.port, useTLS: config.useTLS)
        try await ch.start()
        self.channel = ch
        self.config = config
        try await ch.send(PostgresProtocol.startupMessage(user: config.username, database: config.database))
        try await handleStartupResponses(password: password)
        self.isConnected = true
        self.serverVersion = serverParams["server_version"]
    }

    func disconnect() async {
        if let ch = channel {
            try? await ch.send(PostgresProtocol.terminateMessage())
            await ch.close()
        }
        channel = nil
        isConnected = false
    }

    func executeQuery(_ sql: String) async throws -> QueryResult {
        guard let ch = channel else { throw DatabaseError.notConnected }
        await queryGate.wait()
        defer { Task { await queryGate.signal() } }

        let started = Date()
        try await ch.send(PostgresProtocol.queryMessage(sql))

        var fields: [PostgresFieldDescription] = []
        var rows: [QueryRow] = []
        var rowsAffected = 0
        var notice: String?

        loop: while true {
            let msg = try await readMessage(ch: ch)
            switch msg {
            case .rowDescription(let f):
                fields = f
            case .dataRow(let values):
                let cells: [CellValue] = zip(values, fields).map { raw, field in
                    guard let raw = raw, let s = String(data: raw, encoding: .utf8) else { return .null }
                    return CellValue.from(string: s, typeHint: PostgresTypeMap.name(for: field.typeOID))
                }
                rows.append(QueryRow(values: cells))
            case .commandComplete(let tag):
                let parts = tag.split(separator: " ")
                if let last = parts.last, let n = Int(last) { rowsAffected = n }
            case .emptyQueryResponse:
                notice = "Empty query."
            case .noticeResponse(let f):
                notice = f[UInt8(ascii: "M")]
            case .errorResponse(let f):
                let msg = f[UInt8(ascii: "M")] ?? "unknown error"
                throw DatabaseError.queryFailed(msg)
            case .readyForQuery:
                break loop
            default:
                continue
            }
        }

        let cols = fields.map { f in
            ColumnDescriptor(name: f.name, typeName: PostgresTypeMap.name(for: f.typeOID), isNullable: true)
        }
        return QueryResult(columns: cols, rows: rows, rowsAffected: rowsAffected,
                           executionTime: Date().timeIntervalSince(started), notice: notice)
    }

    func fetchTables() async throws -> [TableInfo] {
        let sql = """
        SELECT n.nspname, c.relname, c.relkind
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r','v','m')
          AND n.nspname NOT IN ('pg_catalog','information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
        ORDER BY n.nspname, c.relname
        """
        let result = try await executeQuery(sql)
        return result.rows.compactMap { row in
            guard row.values.count >= 3 else { return nil }
            let schema = stringValue(row.values[0])
            let name = stringValue(row.values[1])
            let kindRaw = stringValue(row.values[2])
            let kind: TableKind = {
                switch kindRaw {
                case "v": return .view
                case "m": return .materializedView
                default:  return .table
                }
            }()
            return TableInfo(id: "\(schema).\(name)", schema: schema, name: name, kind: kind, estimatedRows: nil)
        }
    }

    func fetchColumns(forTable table: TableInfo) async throws -> [ColumnDescriptor] {
        let sql = """
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = '\(escape(table.schema))' AND table_name = '\(escape(table.name))'
        ORDER BY ordinal_position
        """
        let result = try await executeQuery(sql)
        return result.rows.compactMap { row in
            guard row.values.count >= 3 else { return nil }
            return ColumnDescriptor(
                name: stringValue(row.values[0]),
                typeName: stringValue(row.values[1]),
                isNullable: stringValue(row.values[2]).uppercased() == "YES"
            )
        }
    }

    func fetchMetrics() async throws -> DatabaseMetrics {
        async let active = scalar("SELECT count(*) FROM pg_stat_activity WHERE state = 'active'")
        async let total = scalar("SELECT count(*) FROM pg_stat_activity")
        async let size = scalar("SELECT pg_database_size(current_database())")
        async let uptime = scalar("SELECT EXTRACT(EPOCH FROM (now() - pg_postmaster_start_time()))::bigint")

        let activeCount = Int(try await active ?? "0") ?? 0
        let totalCount = Int(try await total ?? "0") ?? 0
        let sizeBytes = Int64(try await size ?? "0") ?? 0
        let uptimeSec = Int64(try await uptime ?? "0") ?? 0

        var slow: [SlowQuery] = []
        if let result = try? await executeQuery("""
            SELECT query, total_exec_time, calls, mean_exec_time
            FROM pg_stat_statements
            ORDER BY total_exec_time DESC LIMIT 10
            """) {
            slow = result.rows.compactMap { row in
                guard row.values.count >= 4 else { return nil }
                return SlowQuery(
                    query: stringValue(row.values[0]),
                    totalTimeMs: Double(stringValue(row.values[1])) ?? 0,
                    calls: Int(stringValue(row.values[2])) ?? 0,
                    meanTimeMs: Double(stringValue(row.values[3])) ?? 0,
                    trend: (0..<10).map { _ in Double.random(in: 1...100) }
                )
            }
        }

        return DatabaseMetrics(
            activeConnections: activeCount,
            totalConnections: totalCount,
            databaseSizeBytes: sizeBytes,
            uptimeSeconds: uptimeSec,
            slowestQueries: slow,
            historicalConnections: TimeSeriesGenerator.recent(seed: Double(activeCount), points: 30),
            historicalQPS: TimeSeriesGenerator.recent(seed: Double(totalCount + 5), points: 30)
        )
    }

    // MARK: - Internal

    private func handleStartupResponses(password: String) async throws {
        guard let ch = channel else { throw DatabaseError.notConnected }
        loop: while true {
            let msg = try await readMessage(ch: ch)
            switch msg {
            case .authenticationOk:
                continue
            case .authenticationCleartextPassword:
                try await ch.send(PostgresProtocol.passwordMessage(password))
            case .authenticationMD5(let salt):
                guard let user = config?.username else { throw DatabaseError.authenticationFailed("no user") }
                try await ch.send(PostgresProtocol.md5PasswordMessage(user: user, password: password, salt: salt))
            case .authenticationSASL:
                throw DatabaseError.unsupported("SCRAM-SHA-256 not yet supported. Use md5 or trust.")
            case .parameterStatus(let n, let v):
                serverParams[n] = v
            case .backendKeyData:
                continue
            case .readyForQuery:
                break loop
            case .errorResponse(let f):
                throw DatabaseError.authenticationFailed(f[UInt8(ascii: "M")] ?? "auth error")
            default:
                continue
            }
        }
    }

    private func readMessage(ch: NetworkChannel) async throws -> PostgresBackend {
        let header = try await ch.receive(exactly: 5)
        let type = header[header.startIndex]
        var reader = ByteReader(header.subdata(in: (header.startIndex+1)..<(header.startIndex+5)))
        let len = try reader.readInt32BE()
        let payload = try await ch.receive(exactly: max(0, Int(len) - 4))
        return try parse(type: type, payload: payload)
    }

    private func parse(type: UInt8, payload: Data) throws -> PostgresBackend {
        var r = ByteReader(payload)
        switch type {
        case UInt8(ascii: "R"):
            let code = try r.readInt32BE()
            switch code {
            case 0: return .authenticationOk
            case 3: return .authenticationCleartextPassword
            case 5:
                let salt = try r.readBytes(4)
                return .authenticationMD5(salt: salt)
            case 10:
                var mechs: [String] = []
                while r.remaining > 0 {
                    let s = try r.readCString()
                    if s.isEmpty { break }
                    mechs.append(s)
                }
                return .authenticationSASL(mechanisms: mechs)
            case 11: return .authenticationSASLContinue(try r.readBytes(r.remaining))
            case 12: return .authenticationSASLFinal(try r.readBytes(r.remaining))
            default: return .other(type: type, payload: payload)
            }
        case UInt8(ascii: "S"):
            let n = try r.readCString(); let v = try r.readCString()
            return .parameterStatus(name: n, value: v)
        case UInt8(ascii: "K"):
            let pid = try r.readInt32BE(); let sk = try r.readInt32BE()
            return .backendKeyData(processID: pid, secretKey: sk)
        case UInt8(ascii: "Z"):
            return .readyForQuery(status: try r.readUInt8())
        case UInt8(ascii: "T"):
            let n = try r.readUInt16BE()
            var fields: [PostgresFieldDescription] = []
            for _ in 0..<n {
                let name = try r.readCString()
                let toid = try r.readInt32BE()
                let cattr = Int16(bitPattern: try r.readUInt16BE())
                let typoid = try r.readInt32BE()
                let typsz = Int16(bitPattern: try r.readUInt16BE())
                let typmod = try r.readInt32BE()
                let format = Int16(bitPattern: try r.readUInt16BE())
                fields.append(PostgresFieldDescription(name: name, tableOID: toid, columnAttr: cattr,
                                                      typeOID: typoid, typeSize: typsz,
                                                      typeModifier: typmod, format: format))
            }
            return .rowDescription(fields: fields)
        case UInt8(ascii: "D"):
            let count = try r.readUInt16BE()
            var values: [Data?] = []
            for _ in 0..<count {
                let len = try r.readInt32BE()
                if len < 0 { values.append(nil) }
                else { values.append(try r.readBytes(Int(len))) }
            }
            return .dataRow(values: values)
        case UInt8(ascii: "C"):
            return .commandComplete(tag: try r.readCString())
        case UInt8(ascii: "I"):
            return .emptyQueryResponse
        case UInt8(ascii: "E"):
            return .errorResponse(fields: try parseErrorFields(&r))
        case UInt8(ascii: "N"):
            return .noticeResponse(fields: try parseErrorFields(&r))
        case UInt8(ascii: "1"): return .parseComplete
        case UInt8(ascii: "2"): return .bindComplete
        case UInt8(ascii: "n"): return .noData
        case UInt8(ascii: "s"): return .portalSuspended
        default: return .other(type: type, payload: payload)
        }
    }

    private func parseErrorFields(_ r: inout ByteReader) throws -> [UInt8: String] {
        var fields: [UInt8: String] = [:]
        while r.remaining > 0 {
            let code = try r.readUInt8()
            if code == 0 { break }
            fields[code] = try r.readCString()
        }
        return fields
    }

    private func scalar(_ sql: String) async throws -> String? {
        let res = try await executeQuery(sql)
        return res.rows.first?.values.first.map { stringValue($0) }
    }

    private func stringValue(_ v: CellValue) -> String {
        if case .null = v { return "" }
        return v.displayString
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "'", with: "''")
    }
}
