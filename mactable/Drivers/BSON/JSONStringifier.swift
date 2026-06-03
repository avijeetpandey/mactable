//
//  JSONStringifier.swift
//  mactable
//

import Foundation

enum JSONStringifier {
    static func stringify(_ doc: BSONDocument) -> String {
        var out = "{"
        for (i, key) in doc.keys.enumerated() {
            if i > 0 { out += ", " }
            out += "\"\(key)\": "
            if let v = doc.storage[key] { out += stringify(v) }
        }
        out += "}"
        return out
    }

    static func stringify(_ v: BSONValue) -> String {
        switch v {
        case .string(let s): return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .document(let d): return stringify(d)
        case .array(let arr):  return "[" + arr.map { stringify($0) }.joined(separator: ", ") + "]"
        default: return v.asString
        }
    }
}
