//
//  BSONValue.swift
//  mactable
//
//  Minimal BSON types sufficient for MongoDB OP_MSG commands and result decoding.
//

import Foundation

indirect enum BSONValue: Hashable {
    case double(Double)
    case string(String)
    case document(BSONDocument)
    case array([BSONValue])
    case binary(Data)
    case objectID(Data)        // 12 bytes
    case bool(Bool)
    case datetime(Int64)
    case null
    case int32(Int32)
    case int64(Int64)
    case timestamp(UInt64)
    case decimal128(Data)      // 16 bytes
}

struct BSONDocument: Hashable {
    private(set) var keys: [String] = []
    private(set) var storage: [String: BSONValue] = [:]

    init() {}

    init(_ pairs: [(String, BSONValue)]) {
        for (k, v) in pairs { self[k] = v }
    }

    subscript(key: String) -> BSONValue? {
        get { storage[key] }
        set {
            if let nv = newValue {
                if storage[key] == nil { keys.append(key) }
                storage[key] = nv
            } else {
                storage.removeValue(forKey: key)
                keys.removeAll { $0 == key }
            }
        }
    }

    var isEmpty: Bool { keys.isEmpty }
}
