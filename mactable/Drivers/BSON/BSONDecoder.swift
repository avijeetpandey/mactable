//
//  BSONDecoder.swift
//  mactable
//

import Foundation

enum BSONDecoder {
    static func decode(_ data: Data) throws -> BSONDocument {
        var r = ByteReader(data)
        return try readDoc(&r)
    }

    private static func readDoc(_ r: inout ByteReader) throws -> BSONDocument {
        let total = Int(try r.readInt32LE())
        let endIndex = r.index + (total - 4)
        var doc = BSONDocument()
        while r.index < endIndex - 1 {
            let type = try r.readUInt8()
            if type == 0 { break }
            let name = try r.readCString()
            doc[name] = try readValue(type: type, r: &r)
        }
        if r.index < endIndex { _ = try? r.readUInt8() }
        return doc
    }

    private static func readValue(type: UInt8, r: inout ByteReader) throws -> BSONValue {
        switch type {
        case 0x01: return .double(try r.readDoubleLE())
        case 0x02:
            let len = Int(try r.readInt32LE())
            let bytes = try r.readBytes(len)
            let trimmed = bytes.dropLast()
            return .string(String(data: trimmed, encoding: .utf8) ?? "")
        case 0x03: return .document(try readDoc(&r))
        case 0x04:
            let sub = try readDoc(&r)
            let arr = sub.keys.compactMap { sub.storage[$0] }
            return .array(arr)
        case 0x05:
            let len = Int(try r.readInt32LE())
            _ = try r.readUInt8() // subtype
            return .binary(try r.readBytes(len))
        case 0x07: return .objectID(try r.readBytes(12))
        case 0x08: return .bool(try r.readUInt8() != 0)
        case 0x09: return .datetime(try r.readInt64LE())
        case 0x0A: return .null
        case 0x10: return .int32(try r.readInt32LE())
        case 0x11: return .timestamp(UInt64(bitPattern: try r.readInt64LE()))
        case 0x12: return .int64(try r.readInt64LE())
        case 0x13: return .decimal128(try r.readBytes(16))
        case 0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F:
            // undefined, regex, dbpointer, code, symbol, code-w-scope — skip best effort
            return .null
        default:
            return .null
        }
    }
}

extension BSONValue {
    var asString: String {
        switch self {
        case .string(let s): return s
        case .double(let d): return String(d)
        case .int32(let i):  return String(i)
        case .int64(let i):  return String(i)
        case .bool(let b):   return b ? "true" : "false"
        case .null:          return "null"
        case .objectID(let d): return "ObjectId(\"\(d.map { String(format: "%02x", $0) }.joined()))\""
        case .datetime(let t): return ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(t) / 1000))
        case .document(let d): return JSONStringifier.stringify(d)
        case .array(let arr):  return "[" + arr.map { $0.asString }.joined(separator: ", ") + "]"
        case .binary(let d):   return "Binary(\(d.count) bytes)"
        case .timestamp(let t): return "Timestamp(\(t))"
        case .decimal128(let d): return "Decimal128(0x\(d.prefix(8).map { String(format: "%02x", $0) }.joined()))"
        }
    }
}
