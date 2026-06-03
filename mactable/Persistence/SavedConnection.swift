//
//  SavedConnection.swift
//  mactable
//

import Foundation
import SwiftData

@Model
final class SavedConnection {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var host: String
    var port: Int
    var username: String
    var database: String
    var useTLS: Bool
    var createdAt: Date
    var lastUsedAt: Date?

    init(id: UUID = UUID(),
         name: String,
         kind: DatabaseKind,
         host: String,
         port: Int,
         username: String,
         database: String,
         useTLS: Bool = false) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.host = host
        self.port = port
        self.username = username
        self.database = database
        self.useTLS = useTLS
        self.createdAt = Date()
    }

    var kind: DatabaseKind {
        get { DatabaseKind(rawValue: kindRaw) ?? .postgres }
        set { kindRaw = newValue.rawValue }
    }

    var config: ConnectionConfig {
        ConnectionConfig(id: id, name: name, kind: kind, host: host, port: port,
                         username: username, database: database, useTLS: useTLS)
    }

    func update(from config: ConnectionConfig) {
        self.name = config.name
        self.kindRaw = config.kind.rawValue
        self.host = config.host
        self.port = config.port
        self.username = config.username
        self.database = config.database
        self.useTLS = config.useTLS
    }
}
