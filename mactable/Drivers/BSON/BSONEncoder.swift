//
//  BSONEncoder.swift
//  mactable
//

import Foundation

enum BSONEncoder {
    static func encode(_ doc: BSONDocument) -> Data {
        var body = ByteWriter()
        for key in doc.keys {
            guard let v = doc.storage[key] else { continue }
            writeElement(&body, name: key, value: v)
        }
        body.writeUInt8(0)
        var out = ByteWriter()
        out.writeInt32LE(Int32(body.data.count + 4))
        out.writeBytes(body.data)
        return out.data
    }

    private static func writeElement(_ w: inout ByteWriter, name: String, value: BSONValue) {
        switch value {
        case .double(let d):
            w.writeUInt8(0x01); writeKey(&w, name); w.writeDoubleLE(d)
        case .string(let s):
            w.writeUInt8(0x02); writeKey(&w, name)
            let bytes = (s.data(using: .utf8) ?? Data())
            w.writeInt32LE(Int32(bytes.count + 1))
            w.writeBytes(bytes); w.writeUInt8(0)
        case .document(let d):
            w.writeUInt8(0x03); writeKey(&w, name); w.writeBytes(encode(d))
        case .array(let arr):
            w.writeUInt8(0x04); writeKey(&w, name)
            var doc = BSONDocument()
            for (i, v) in arr.enumerated() { doc[String(i)] = v }
            w.writeBytes(encode(doc))
        case .binary(let data):
            w.writeUInt8(0x05); writeKey(&w, name)
            w.writeInt32LE(Int32(data.count))
            w.writeUInt8(0x00); w.writeBytes(data)
        case .objectID(let oid):
            w.writeUInt8(0x07); writeKey(&w, name); w.writeBytes(oid)
        case .bool(let b):
            w.writeUInt8(0x08); writeKey(&w, name); w.writeUInt8(b ? 1 : 0)
        case .datetime(let v):
            w.writeUInt8(0x09); writeKey(&w, name); w.writeInt64LE(v)
        case .null:
            w.writeUInt8(0x0A); writeKey(&w, name)
        case .int32(let v):
            w.writeUInt8(0x10); writeKey(&w, name); w.writeInt32LE(v)
        case .int64(let v):
            w.writeUInt8(0x12); writeKey(&w, name); w.writeInt64LE(v)
        case .timestamp(let v):
            w.writeUInt8(0x11); writeKey(&w, name); w.writeInt64LE(Int64(bitPattern: v))
        case .decimal128(let d):
            w.writeUInt8(0x13); writeKey(&w, name); w.writeBytes(d)
        }
    }

    private static func writeKey(_ w: inout ByteWriter, _ s: String) {
        if let bytes = s.data(using: .utf8) { w.writeBytes(bytes) }
        w.writeUInt8(0)
    }
}
