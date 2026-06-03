//
//  MongoDriver.swift
//  mactable
//
//  Minimal MongoDB client implementing OP_MSG (opcode 2013).
//  Supports: unauthenticated connections + SCRAM-SHA-1/256 NOT yet wired.
//  For authenticated servers, configure with no auth or use a SOCKS tunnel for now.
//  Query language: parses simple `db.collection.find({...})` / `aggregate([...])` / `count()`.
//

import Foundation

final class MongoDriver: DatabaseDriver, @unchecked Sendable {
    let kind: DatabaseKind = .mongodb
    private(set) var isConnected: Bool = false
    private(set) var serverVersion: String?

    private var channel: NetworkChannel?
    private var requestID: Int32 = 0
    private var config: ConnectionConfig?
    private let queryGate = AsyncSemaphore(value: 1)

    func connect(config: ConnectionConfig, password: String) async throws {
        let ch = NetworkChannel(host: config.host, port: config.port, useTLS: config.useTLS)
        try await ch.start()
        self.channel = ch
        self.config = config

        // hello/isMaster handshake
        var hello = BSONDocument()
        hello["hello"] = .int32(1)
        hello["$db"] = .string("admin")
        let reply = try await runCommand(hello)
        if let v = reply["version"], case .string(let s) = v { self.serverVersion = s }
        if let ok = reply["ok"], case .double(let d) = ok, d != 1.0 {
            throw DatabaseError.connectionFailed("hello returned ok=\(d)")
        }
        if !config.username.isEmpty {
            try await scramAuthenticate(username: config.username, password: password,
                                        authDB: config.database.isEmpty ? "admin" : config.database)
        }
        self.isConnected = true
    }

    func disconnect() async {
        if let ch = channel { await ch.close() }
        channel = nil
        isConnected = false
    }

    func executeQuery(_ sql: String) async throws -> QueryResult {
        guard channel != nil else { throw DatabaseError.notConnected }
        await queryGate.wait()
        defer { Task { await queryGate.signal() } }

        let started = Date()
        let parsed = try MongoQueryParser.parse(sql, defaultDB: config?.database ?? "admin")
        let reply = try await runCommand(parsed.command, db: parsed.database)

        if let okVal = reply["ok"], case .double(let okD) = okVal, okD != 1.0 {
            let msg: String = (reply["errmsg"].flatMap { if case .string(let s) = $0 { return s } else { return nil } }) ?? "command failed"
            throw DatabaseError.queryFailed(msg)
        }

        if let cursor = reply["cursor"], case .document(let cdoc) = cursor,
           let firstBatch = cdoc["firstBatch"], case .array(let docs) = firstBatch {
            let result = renderDocuments(docs)
            return QueryResult(columns: result.columns, rows: result.rows,
                               rowsAffected: result.rows.count,
                               executionTime: Date().timeIntervalSince(started),
                               notice: nil)
        }
        // Single-document reply (e.g., count, insert ack, status). Render as a 1-row table.
        let result = renderDocuments([.document(reply)])
        return QueryResult(columns: result.columns, rows: result.rows,
                           rowsAffected: result.rows.count,
                           executionTime: Date().timeIntervalSince(started),
                           notice: nil)
    }

    func fetchTables() async throws -> [TableInfo] {
        let dbName = config?.database ?? "admin"
        var cmd = BSONDocument()
        cmd["listCollections"] = .int32(1)
        cmd["nameOnly"] = .bool(true)
        let reply = try await runCommand(cmd, db: dbName)
        guard case .document(let cursor)? = reply["cursor"],
              case .array(let arr)? = cursor["firstBatch"] else { return [] }
        return arr.compactMap { v in
            guard case .document(let d) = v,
                  case .string(let name)? = d["name"] else { return nil }
            return TableInfo(id: "\(dbName).\(name)", schema: dbName, name: name,
                             kind: .collection, estimatedRows: nil)
        }
    }

    func fetchColumns(forTable table: TableInfo) async throws -> [ColumnDescriptor] {
        // Sample one document to infer keys
        var cmd = BSONDocument()
        cmd["find"] = .string(table.name)
        cmd["limit"] = .int32(1)
        let reply = try await runCommand(cmd, db: table.schema)
        guard case .document(let cursor)? = reply["cursor"],
              case .array(let arr)? = cursor["firstBatch"],
              let first = arr.first,
              case .document(let doc) = first else {
            return [ColumnDescriptor(name: "_id", typeName: "ObjectId", isNullable: false)]
        }
        return doc.keys.map { key in
            ColumnDescriptor(name: key, typeName: bsonTypeName(doc.storage[key]), isNullable: true)
        }
    }

    func fetchMetrics() async throws -> DatabaseMetrics {
        var status = BSONDocument()
        status["serverStatus"] = .int32(1)
        let reply = try await runCommand(status, db: "admin")

        var active = 0, total = 0
        if case .document(let conns)? = reply["connections"] {
            if case .int32(let c)? = conns["current"] { active = Int(c) }
            if case .int32(let a)? = conns["available"] { total = active + Int(a) }
        }
        var size: Int64 = 0
        var stats = BSONDocument()
        stats["dbStats"] = .int32(1)
        if let r = try? await runCommand(stats, db: config?.database ?? "admin"),
           case .double(let d)? = r["dataSize"] { size = Int64(d) }

        var uptime: Int64 = 0
        if case .double(let u)? = reply["uptime"] { uptime = Int64(u) }

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

    // MARK: - SCRAM (skeleton — full impl out of scope; reject to surface clear error)

    private func scramAuthenticate(username: String, password: String, authDB: String) async throws {
        throw DatabaseError.unsupported("MongoDB SCRAM auth is not yet supported by the built-in driver. Connect to an unauthenticated MongoDB or via an SSH tunnel without auth.")
    }

    // MARK: - OP_MSG

    private func runCommand(_ command: BSONDocument, db: String? = nil) async throws -> BSONDocument {
        guard let ch = channel else { throw DatabaseError.notConnected }
        var cmd = command
        cmd["$db"] = .string(db ?? config?.database ?? "admin")

        let bson = BSONEncoder.encode(cmd)
        var section = ByteWriter()
        section.writeUInt8(0) // section kind 0
        section.writeBytes(bson)

        var body = ByteWriter()
        body.writeUInt32LE(0) // flagBits
        body.writeBytes(section.data)

        var msg = ByteWriter()
        let length = 16 + body.data.count
        msg.writeInt32LE(Int32(length))
        requestID &+= 1
        msg.writeInt32LE(requestID)
        msg.writeInt32LE(0) // responseTo
        msg.writeInt32LE(2013) // OP_MSG
        msg.writeBytes(body.data)
        try await ch.send(msg.data)

        let header = try await ch.receive(exactly: 16)
        var hr = ByteReader(header)
        let totalLen = Int(try hr.readInt32LE())
        _ = try hr.readInt32LE() // requestID
        _ = try hr.readInt32LE() // responseTo
        let opcode = try hr.readInt32LE()
        let payload = try await ch.receive(exactly: totalLen - 16)

        guard opcode == 2013 else {
            throw DatabaseError.protocolError("unexpected opcode \(opcode)")
        }
        var pr = ByteReader(payload)
        _ = try pr.readUInt32LE() // flag bits
        let kind = try pr.readUInt8()
        guard kind == 0 else { throw DatabaseError.protocolError("unsupported section kind \(kind)") }
        let docData = payload.subdata(in: pr.index..<payload.count)
        return try BSONDecoder.decode(docData)
    }

    // MARK: - Rendering

    private func renderDocuments(_ values: [BSONValue]) -> (columns: [ColumnDescriptor], rows: [QueryRow]) {
        var keys: [String] = []
        var seen = Set<String>()
        for v in values {
            if case .document(let d) = v {
                for k in d.keys where !seen.contains(k) { keys.append(k); seen.insert(k) }
            }
        }
        if keys.isEmpty { keys = ["value"] }
        let cols = keys.map { ColumnDescriptor(name: $0, typeName: "bson", isNullable: true) }
        var rows: [QueryRow] = []
        for v in values {
            if case .document(let d) = v {
                rows.append(QueryRow(values: keys.map { CellValue.json(JSONStringifier.stringify(d.storage[$0] ?? .null)) }))
            } else {
                rows.append(QueryRow(values: [CellValue.json(JSONStringifier.stringify(v))]))
            }
        }
        return (cols, rows)
    }

    private func bsonTypeName(_ v: BSONValue?) -> String {
        guard let v = v else { return "null" }
        switch v {
        case .double: return "double"
        case .string: return "string"
        case .document: return "object"
        case .array: return "array"
        case .binary: return "binary"
        case .objectID: return "ObjectId"
        case .bool: return "bool"
        case .datetime: return "date"
        case .null: return "null"
        case .int32: return "int32"
        case .int64: return "int64"
        case .timestamp: return "timestamp"
        case .decimal128: return "decimal128"
        }
    }
}
