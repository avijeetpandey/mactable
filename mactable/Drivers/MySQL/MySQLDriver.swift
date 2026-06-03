//
//  MySQLDriver.swift
//  mactable
//
//  Native Swift MySQL client (text protocol).
//  Supports: mysql_native_password, caching_sha2_password (fast-path).
//

import Foundation

private struct MySQLPacket {
    let sequenceID: UInt8
    let payload: Data
}

private enum MySQLCapability {
    static let LONG_PASSWORD: UInt32      = 0x00000001
    static let LONG_FLAG: UInt32          = 0x00000004
    static let CONNECT_WITH_DB: UInt32    = 0x00000008
    static let PROTOCOL_41: UInt32        = 0x00000200
    static let TRANSACTIONS: UInt32       = 0x00002000
    static let SECURE_CONNECTION: UInt32  = 0x00008000
    static let MULTI_RESULTS: UInt32      = 0x00020000
    static let PLUGIN_AUTH: UInt32        = 0x00080000
    static let DEPRECATE_EOF: UInt32      = 0x01000000
    static var CLIENT_DEFAULTS: UInt32 {
        LONG_PASSWORD | LONG_FLAG | PROTOCOL_41 | TRANSACTIONS |
        SECURE_CONNECTION | MULTI_RESULTS | PLUGIN_AUTH | DEPRECATE_EOF
    }
}

final class MySQLDriver: DatabaseDriver, @unchecked Sendable {
    let kind: DatabaseKind = .mysql
    private(set) var isConnected: Bool = false
    private(set) var serverVersion: String?

    private var channel: NetworkChannel?
    private var sequence: UInt8 = 0
    private var capabilities: UInt32 = 0
    private var config: ConnectionConfig?
    private let queryGate = AsyncSemaphore(value: 1)

    func connect(config: ConnectionConfig, password: String) async throws {
        let ch = NetworkChannel(host: config.host, port: config.port, useTLS: config.useTLS)
        try await ch.start()
        self.channel = ch
        self.config = config

        let handshake = try await readPacket()
        try await processHandshake(handshake.payload, password: password, db: config.database, user: config.username)
        self.isConnected = true
    }

    func disconnect() async {
        if let ch = channel {
            // COM_QUIT
            sequence = 0
            try? await sendPacket(Data([0x01]))
            await ch.close()
        }
        channel = nil
        isConnected = false
    }

    func executeQuery(_ sql: String) async throws -> QueryResult {
        guard channel != nil else { throw DatabaseError.notConnected }
        await queryGate.wait()
        defer { Task { await queryGate.signal() } }

        let started = Date()
        sequence = 0
        var payload = Data([0x03]) // COM_QUERY
        payload.append(sql.data(using: .utf8) ?? Data())
        try await sendPacket(payload)

        let first = try await readPacket()
        let head = first.payload.first ?? 0
        if head == 0x00 || head == 0xFE && first.payload.count < 9 {
            // OK packet
            var r = ByteReader(first.payload, index: 1)
            let affected = try r.readLengthEncodedInt()
            return QueryResult(columns: [], rows: [],
                               rowsAffected: Int(affected), executionTime: Date().timeIntervalSince(started),
                               notice: nil)
        }
        if head == 0xFF {
            throw DatabaseError.queryFailed(parseError(first.payload))
        }

        // Result set: column count
        var r = ByteReader(first.payload)
        let columnCount = Int(try r.readLengthEncodedInt())

        var fields: [ColumnDescriptor] = []
        for _ in 0..<columnCount {
            let pkt = try await readPacket()
            fields.append(try parseColumnDef(pkt.payload))
        }
        if (capabilities & MySQLCapability.DEPRECATE_EOF) == 0 {
            _ = try await readPacket() // EOF after columns
        }

        var rows: [QueryRow] = []
        while true {
            let pkt = try await readPacket()
            let h = pkt.payload.first ?? 0
            if h == 0xFE && pkt.payload.count < 9 { break } // EOF / OK terminator
            if h == 0xFF { throw DatabaseError.queryFailed(parseError(pkt.payload)) }
            var rr = ByteReader(pkt.payload)
            var values: [CellValue] = []
            for col in fields {
                if (try? rr.peekUInt8()) == 0xFB {
                    _ = try rr.readUInt8()
                    values.append(.null)
                } else {
                    let s = try rr.readLengthEncodedString() ?? ""
                    values.append(CellValue.from(string: s, typeHint: col.typeName))
                }
            }
            rows.append(QueryRow(values: values))
        }

        return QueryResult(columns: fields, rows: rows, rowsAffected: rows.count,
                           executionTime: Date().timeIntervalSince(started), notice: nil)
    }

    func fetchTables() async throws -> [TableInfo] {
        let dbName = config?.database ?? ""
        let sql = """
        SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE, TABLE_ROWS
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema','sys')
        \(dbName.isEmpty ? "" : "AND TABLE_SCHEMA = '\(escape(dbName))'")
        ORDER BY TABLE_SCHEMA, TABLE_NAME
        """
        let res = try await executeQuery(sql)
        return res.rows.compactMap { row in
            guard row.values.count >= 3 else { return nil }
            let schema = row.values[0].displayString
            let name = row.values[1].displayString
            let type = row.values[2].displayString
            let rows = row.values.count > 3 ? Int(row.values[3].displayString) : nil
            let tk: TableKind = type.uppercased().contains("VIEW") ? .view : .table
            return TableInfo(id: "\(schema).\(name)", schema: schema, name: name, kind: tk, estimatedRows: rows)
        }
    }

    func fetchColumns(forTable table: TableInfo) async throws -> [ColumnDescriptor] {
        let sql = """
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA='\(escape(table.schema))' AND TABLE_NAME='\(escape(table.name))'
        ORDER BY ORDINAL_POSITION
        """
        let res = try await executeQuery(sql)
        return res.rows.map { row in
            ColumnDescriptor(name: row.values[0].displayString,
                             typeName: row.values[1].displayString,
                             isNullable: row.values[2].displayString.uppercased() == "YES")
        }
    }

    func fetchMetrics() async throws -> DatabaseMetrics {
        let active = Int((try? await scalar("SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE COMMAND <> 'Sleep'")) ?? "0") ?? 0
        let total  = Int((try? await scalar("SELECT COUNT(*) FROM information_schema.PROCESSLIST")) ?? "0") ?? 0
        let size   = Int64((try? await scalar("SELECT IFNULL(SUM(data_length+index_length),0) FROM information_schema.TABLES")) ?? "0") ?? 0
        let uptime = Int64((try? await scalar("SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Uptime'")) ?? "0") ?? 0
        return DatabaseMetrics(
            activeConnections: active,
            totalConnections: total,
            databaseSizeBytes: size,
            uptimeSeconds: uptime,
            slowestQueries: [],
            historicalConnections: TimeSeriesGenerator.recent(seed: Double(active + 1), points: 30),
            historicalQPS: TimeSeriesGenerator.recent(seed: Double(total + 5), points: 30)
        )
    }

    // MARK: - Handshake

    private func processHandshake(_ payload: Data, password: String, db: String, user: String) async throws {
        var r = ByteReader(payload)
        let proto = try r.readUInt8()
        guard proto == 10 else { throw DatabaseError.protocolError("unsupported protocol \(proto)") }
        let versionStr = try r.readCString()
        self.serverVersion = versionStr
        _ = try r.readInt32LE() // thread id
        let scramble1 = try r.readBytes(8)
        _ = try r.readUInt8() // filler
        let capLow = try r.readUInt16BE() // careful: actually LE
        // Actually capability flags are LE 2 bytes; re-read properly:
        var r2 = ByteReader(payload)
        _ = try r2.readUInt8()
        _ = try r2.readCString()
        _ = try r2.readInt32LE()
        _ = try r2.readBytes(8)
        _ = try r2.readUInt8()
        let capLowLE = UInt32(try r2.readUInt8()) | (UInt32(try r2.readUInt8()) << 8)
        _ = capLow // silence
        var capabilities: UInt32 = capLowLE

        if r2.remaining > 0 {
            _ = try r2.readUInt8() // charset
            _ = try r2.readBytes(2) // status flags
            let capHigh = UInt32(try r2.readUInt8()) | (UInt32(try r2.readUInt8()) << 8)
            capabilities |= (capHigh << 16)
            let authDataLen = Int(try r2.readUInt8())
            _ = try r2.readBytes(10) // reserved
            let scramble2Len = max(13, authDataLen - 8)
            let scramble2 = try r2.readBytes(scramble2Len)
            // strip trailing null
            var fullNonce = scramble1
            fullNonce.append(scramble2.prefix(scramble2.count > 0 && scramble2.last == 0 ? scramble2.count - 1 : scramble2.count))
            var pluginName = "mysql_native_password"
            if (capabilities & MySQLCapability.PLUGIN_AUTH) != 0, r2.remaining > 0 {
                pluginName = try r2.readCString()
            }
            self.capabilities = capabilities & MySQLCapability.CLIENT_DEFAULTS
            try await sendHandshakeResponse(user: user, password: password, db: db, nonce: fullNonce, plugin: pluginName)
        } else {
            try await sendHandshakeResponse(user: user, password: password, db: db, nonce: scramble1, plugin: "mysql_native_password")
        }

        // Auth response loop
        loop: while true {
            let pkt = try await readPacket()
            let h = pkt.payload.first ?? 0
            switch h {
            case 0x00: break loop // OK
            case 0xFF: throw DatabaseError.authenticationFailed(parseError(pkt.payload))
            case 0xFE:
                // Auth switch request
                var rs = ByteReader(pkt.payload, index: 1)
                let plugin = try rs.readCString()
                let salt = try rs.readBytes(rs.remaining)
                let trimmed = salt.last == 0 ? salt.dropLast() : salt
                let scrambled: Data
                if plugin == "mysql_native_password" {
                    scrambled = MySQLNativePassword.scramble(password: password, nonce: Data(trimmed))
                } else if plugin == "caching_sha2_password" {
                    scrambled = MySQLCachingSHA2Password.scramble(password: password, nonce: Data(trimmed))
                } else {
                    throw DatabaseError.unsupported("auth plugin \(plugin)")
                }
                try await sendPacket(scrambled)
            case 0x01:
                // caching_sha2_password fast/full auth status. 0x01 0x03 = OK fast, 0x01 0x04 = full required (TLS-only path; we error)
                let status = pkt.payload.count > 1 ? pkt.payload[pkt.payload.startIndex + 1] : 0
                if status == 0x03 { continue }
                if status == 0x04 {
                    throw DatabaseError.unsupported("caching_sha2_password full auth requires TLS or RSA exchange (not implemented). Use mysql_native_password.")
                }
            default:
                continue
            }
        }
    }

    private func sendHandshakeResponse(user: String, password: String, db: String, nonce: Data, plugin: String) async throws {
        var capabilities = MySQLCapability.CLIENT_DEFAULTS
        if !db.isEmpty { capabilities |= MySQLCapability.CONNECT_WITH_DB }
        self.capabilities = capabilities

        var w = ByteWriter()
        w.writeUInt32LE(capabilities)
        w.writeUInt32LE(16_777_216) // max packet
        w.writeUInt8(0x21) // utf8 collation
        w.writeBytes(Data(repeating: 0, count: 23))
        w.writeCString(user)
        let scrambled: Data
        switch plugin {
        case "caching_sha2_password":
            scrambled = MySQLCachingSHA2Password.scramble(password: password, nonce: nonce)
        default:
            scrambled = MySQLNativePassword.scramble(password: password, nonce: nonce)
        }
        w.writeUInt8(UInt8(scrambled.count))
        w.writeBytes(scrambled)
        if !db.isEmpty { w.writeCString(db) }
        if (capabilities & MySQLCapability.PLUGIN_AUTH) != 0 {
            w.writeCString(plugin)
        }
        try await sendPacket(w.data)
    }

    // MARK: - Framing

    private func sendPacket(_ payload: Data) async throws {
        guard let ch = channel else { throw DatabaseError.notConnected }
        var w = ByteWriter()
        w.writeUInt8(UInt8(payload.count & 0xFF))
        w.writeUInt8(UInt8((payload.count >> 8) & 0xFF))
        w.writeUInt8(UInt8((payload.count >> 16) & 0xFF))
        w.writeUInt8(sequence)
        sequence &+= 1
        w.writeBytes(payload)
        try await ch.send(w.data)
    }

    private func readPacket() async throws -> MySQLPacket {
        guard let ch = channel else { throw DatabaseError.notConnected }
        let header = try await ch.receive(exactly: 4)
        let len = Int(header[header.startIndex]) | (Int(header[header.startIndex+1]) << 8) | (Int(header[header.startIndex+2]) << 16)
        let seq = header[header.startIndex+3]
        sequence = seq &+ 1
        let payload = try await ch.receive(exactly: len)
        return MySQLPacket(sequenceID: seq, payload: payload)
    }

    private func parseColumnDef(_ data: Data) throws -> ColumnDescriptor {
        var r = ByteReader(data)
        _ = try r.readLengthEncodedString() // catalog
        _ = try r.readLengthEncodedString() // schema
        _ = try r.readLengthEncodedString() // table
        _ = try r.readLengthEncodedString() // org_table
        let name = try r.readLengthEncodedString() ?? ""
        _ = try r.readLengthEncodedString() // org_name
        _ = try r.readLengthEncodedInt() // next_length filler
        _ = try r.readBytes(2) // charset
        _ = try r.readBytes(4) // column length
        let type = try r.readUInt8()
        _ = try r.readBytes(2) // flags
        _ = try r.readUInt8()  // decimals
        return ColumnDescriptor(name: name, typeName: MySQLTypeMap.name(for: type), isNullable: true)
    }

    private func parseError(_ data: Data) -> String {
        guard data.count > 3 else { return "unknown error" }
        // 0xFF, errno (2 bytes LE), '#', SQLState(5), message
        var idx = data.startIndex + 3
        if data.count > idx, data[idx] == UInt8(ascii: "#") {
            idx = data.index(idx, offsetBy: 6)
        }
        return String(data: data.suffix(from: idx), encoding: .utf8) ?? "unknown error"
    }

    private func scalar(_ sql: String) async throws -> String? {
        let res = try await executeQuery(sql)
        return res.rows.first?.values.first?.displayString
    }

    private func escape(_ s: String) -> String { s.replacingOccurrences(of: "'", with: "''") }
}
