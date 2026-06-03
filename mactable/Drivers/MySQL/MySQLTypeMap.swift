//
//  MySQLTypeMap.swift
//  mactable
//

import Foundation

enum MySQLTypeMap {
    static func name(for code: UInt8) -> String {
        switch code {
        case 0x00: return "decimal"
        case 0x01: return "tinyint"
        case 0x02: return "smallint"
        case 0x03: return "int"
        case 0x04: return "float"
        case 0x05: return "double"
        case 0x06: return "null"
        case 0x07: return "timestamp"
        case 0x08: return "bigint"
        case 0x09: return "mediumint"
        case 0x0A: return "date"
        case 0x0B: return "time"
        case 0x0C: return "datetime"
        case 0x0D: return "year"
        case 0x0F: return "varchar"
        case 0x10: return "bit"
        case 0xF6: return "newdecimal"
        case 0xFC: return "blob"
        case 0xFD: return "varstring"
        case 0xFE: return "string"
        case 0xFF: return "geometry"
        default:   return "type:\(code)"
        }
    }
}
