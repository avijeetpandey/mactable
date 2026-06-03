//
//  MongoQueryParser.swift
//  mactable
//
//  Translates simple Mongo-style strings into BSON commands.
//  Supported forms:
//    db.<collection>.find({...}, {projection})
//    db.<collection>.findOne({...})
//    db.<collection>.aggregate([...])
//    db.<collection>.countDocuments({...})
//    db.<collection>.estimatedDocumentCount()
//    {"raw": ...}  (pass JSON command directly)
//

import Foundation

struct MongoParsedQuery {
    let database: String
    let command: BSONDocument
}

enum MongoQueryParser {
    static func parse(_ raw: String, defaultDB: String) throws -> MongoParsedQuery {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") {
            let json = try parseJSONObject(trimmed)
            return MongoParsedQuery(database: defaultDB, command: json)
        }

        guard trimmed.hasPrefix("db.") else {
            throw DatabaseError.queryFailed("Mongo queries must start with 'db.<collection>.<op>(...)' or be a JSON command document.")
        }
        let afterDB = String(trimmed.dropFirst(3))
        guard let dotIdx = afterDB.firstIndex(of: ".") else {
            throw DatabaseError.queryFailed("Missing collection name.")
        }
        let collection = String(afterDB[..<dotIdx])
        let after = afterDB[afterDB.index(after: dotIdx)...]
        guard let parenIdx = after.firstIndex(of: "(") else {
            throw DatabaseError.queryFailed("Missing operation parens.")
        }
        let op = String(after[..<parenIdx])
        guard let close = after.lastIndex(of: ")") else {
            throw DatabaseError.queryFailed("Missing closing paren.")
        }
        let argsRaw = String(after[after.index(after: parenIdx)..<close]).trimmingCharacters(in: .whitespaces)

        var cmd = BSONDocument()
        switch op {
        case "find":
            cmd["find"] = .string(collection)
            let parts = splitTopLevelArgs(argsRaw)
            if let f = parts.first, !f.isEmpty { cmd["filter"] = .document(try parseJSONObject(f)) }
            if parts.count > 1 { cmd["projection"] = .document(try parseJSONObject(parts[1])) }
        case "findOne":
            cmd["find"] = .string(collection)
            cmd["limit"] = .int32(1)
            if !argsRaw.isEmpty { cmd["filter"] = .document(try parseJSONObject(argsRaw)) }
        case "aggregate":
            cmd["aggregate"] = .string(collection)
            if argsRaw.isEmpty {
                cmd["pipeline"] = .array([])
            } else if case .array(let arr) = try parseJSONValue(argsRaw) {
                cmd["pipeline"] = .array(arr)
            } else {
                throw DatabaseError.queryFailed("aggregate expects an array argument.")
            }
            cmd["cursor"] = .document(BSONDocument())
        case "countDocuments", "count":
            cmd["count"] = .string(collection)
            if !argsRaw.isEmpty { cmd["query"] = .document(try parseJSONObject(argsRaw)) }
        case "estimatedDocumentCount":
            cmd["count"] = .string(collection)
        default:
            throw DatabaseError.unsupported("Operation \(op) is not yet supported.")
        }
        return MongoParsedQuery(database: defaultDB, command: cmd)
    }

    private static func splitTopLevelArgs(_ s: String) -> [String] {
        var depth = 0, parts: [String] = [], current = ""
        for ch in s {
            switch ch {
            case "{", "[": depth += 1; current.append(ch)
            case "}", "]": depth -= 1; current.append(ch)
            case "," where depth == 0:
                parts.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            default: current.append(ch)
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append(current.trimmingCharacters(in: .whitespaces))
        }
        return parts
    }

    static func parseJSONObject(_ s: String) throws -> BSONDocument {
        let data = s.data(using: .utf8) ?? Data()
        let obj = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .fragmentsAllowed])
        guard let dict = obj as? [String: Any] else {
            throw DatabaseError.queryFailed("Expected JSON object.")
        }
        return jsonToBSON(dict)
    }

    static func parseJSONValue(_ s: String) throws -> BSONValue {
        let data = s.data(using: .utf8) ?? Data()
        let obj = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .fragmentsAllowed])
        return anyToBSON(obj)
    }

    static func jsonToBSON(_ dict: [String: Any]) -> BSONDocument {
        var doc = BSONDocument()
        for (k, v) in dict { doc[k] = anyToBSON(v) }
        return doc
    }

    static func anyToBSON(_ v: Any) -> BSONValue {
        if let n = v as? NSNumber {
            // Distinguish actual Bools from numeric 0/1 by checking the underlying type.
            let typeID = CFGetTypeID(n)
            if typeID == CFBooleanGetTypeID() {
                return .bool(n.boolValue)
            }
            if CFNumberIsFloatType(n) { return .double(n.doubleValue) }
            let i = n.int64Value
            if i >= Int64(Int32.min) && i <= Int64(Int32.max) { return .int32(Int32(i)) }
            return .int64(i)
        }
        switch v {
        case let s as String: return .string(s)
        case let arr as [Any]: return .array(arr.map { anyToBSON($0) })
        case let dict as [String: Any]: return .document(jsonToBSON(dict))
        case is NSNull: return .null
        default: return .null
        }
    }
}
