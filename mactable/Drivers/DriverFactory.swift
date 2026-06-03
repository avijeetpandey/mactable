//
//  DriverFactory.swift
//  mactable
//

import Foundation

enum DriverFactory {
    static func make(for kind: DatabaseKind) -> DatabaseDriver {
        switch kind {
        case .postgres: return PostgresDriver()
        case .mysql:    return MySQLDriver()
        case .mongodb:  return MongoDriver()
        }
    }
}
