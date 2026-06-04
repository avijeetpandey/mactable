//
//  SQLLiteralFormatter.swift
//  mactable
//
//  Pure value formatter that converts a `CellValue` into a SQL literal
//  suitable for inlining into UPDATE statements. Strings are escaped with
//  doubled-up single quotes per the ANSI standard.
//

import Foundation

enum SQLLiteralFormatter {
    static func format(_ value: CellValue) -> String {
        switch value {
        case .null:           return "NULL"
        case .string(let s):  return "'\(s.replacingOccurrences(of: "'", with: "''"))'"
        case .integer(let i): return String(i)
        case .double(let d):  return String(d)
        case .bool(let b):    return b ? "TRUE" : "FALSE"
        case .date(let d):    return "'\(ISO8601DateFormatter().string(from: d))'"
        case .data(let d):    return "decode('\(d.map { String(format: "%02x", $0) }.joined())', 'hex')"
        case .json(let s):    return "'\(s.replacingOccurrences(of: "'", with: "''"))'"
        }
    }
}
