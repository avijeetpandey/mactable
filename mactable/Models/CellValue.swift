//
//  CellValue.swift
//  mactable
//

import Foundation

enum CellValue: Hashable {
    case null
    case string(String)
    case integer(Int64)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case data(Data)
    case json(String)

    var displayString: String {
        switch self {
        case .null:           return "NULL"
        case .string(let s):  return s
        case .integer(let i): return String(i)
        case .double(let d):  return String(d)
        case .bool(let b):    return b ? "true" : "false"
        case .date(let d):    return ISO8601DateFormatter().string(from: d)
        case .data(let d):    return "0x" + d.prefix(32).map { String(format: "%02x", $0) }.joined()
        case .json(let s):    return s
        }
    }

    var isNull: Bool { if case .null = self { return true } else { return false } }

    var jsonRepresentation: String {
        switch self {
        case .null:           return "null"
        case .string(let s):  return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .integer(let i): return String(i)
        case .double(let d):  return String(d)
        case .bool(let b):    return b ? "true" : "false"
        case .date(let d):    return "\"\(ISO8601DateFormatter().string(from: d))\""
        case .data(let d):    return "\"\(d.base64EncodedString())\""
        case .json(let s):    return s
        }
    }

    static func from(string: String?, typeHint: String = "") -> CellValue {
        guard let s = string else { return .null }
        let lt = typeHint.lowercased()
        if lt.contains("bool") {
            if s == "t" || s.lowercased() == "true"  { return .bool(true) }
            if s == "f" || s.lowercased() == "false" { return .bool(false) }
        }
        if lt.contains("int") || lt.contains("serial") {
            if let i = Int64(s) { return .integer(i) }
        }
        if lt.contains("float") || lt.contains("double") || lt.contains("numeric") || lt.contains("decimal") || lt.contains("real") {
            if let d = Double(s) { return .double(d) }
        }
        if lt.contains("json") { return .json(s) }
        return .string(s)
    }
}
