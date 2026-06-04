//
//  SavedQuery.swift
//  mactable
//
//  Persistent SwiftData model for a user's saved SQL snippet. Bound to a
//  specific connection ID so the command palette can route execution to
//  the right driver.
//

import Foundation
import SwiftData

@Model
final class SavedQuery {
    @Attribute(.unique) var id: UUID
    var name: String
    var sql: String
    var connectionID: UUID
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         name: String,
         sql: String,
         connectionID: UUID,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.sql = sql
        self.connectionID = connectionID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
