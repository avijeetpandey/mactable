//
//  PostgresTypeMap.swift
//  mactable
//

import Foundation

enum PostgresTypeMap {
    static func name(for oid: Int32) -> String {
        switch oid {
        case 16:   return "boolean"
        case 17:   return "bytea"
        case 20:   return "bigint"
        case 21:   return "smallint"
        case 23:   return "integer"
        case 25:   return "text"
        case 700:  return "real"
        case 701:  return "double precision"
        case 1042: return "character"
        case 1043: return "varchar"
        case 1082: return "date"
        case 1083: return "time"
        case 1114: return "timestamp"
        case 1184: return "timestamptz"
        case 1700: return "numeric"
        case 2950: return "uuid"
        case 114, 3802: return "json"
        default:   return "oid:\(oid)"
        }
    }
}
