//
//  ScratchpadNote.swift
//  mactable
//
//  SwiftData model for the inspector markdown scratchpad. One note per
//  connection profile keeps DB-specific runbooks adjacent to the data.
//

import Foundation
import SwiftData

@Model
final class ScratchpadNote {
    @Attribute(.unique) var connectionID: UUID
    var markdown: String
    var updatedAt: Date

    init(connectionID: UUID, markdown: String = "", updatedAt: Date = Date()) {
        self.connectionID = connectionID
        self.markdown = markdown
        self.updatedAt = updatedAt
    }
}
