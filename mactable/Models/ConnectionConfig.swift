//
//  ConnectionConfig.swift
//  mactable
//

import Foundation

struct ConnectionConfig: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var kind: DatabaseKind
    var host: String
    var port: Int
    var username: String
    var database: String
    var useTLS: Bool

    init(id: UUID = UUID(),
         name: String = "New Connection",
         kind: DatabaseKind = .postgres,
         host: String = "localhost",
         port: Int? = nil,
         username: String = "",
         database: String = "",
         useTLS: Bool = false) {
        self.id = id
        self.name = name
        self.kind = kind
        self.host = host
        self.port = port ?? kind.defaultPort
        self.username = username
        self.database = database
        self.useTLS = useTLS
    }
}
