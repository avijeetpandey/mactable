//
//  CommandPaletteItem.swift
//  mactable
//
//  A single executable item surfaced inside the Cmd+K command palette.
//

import Foundation
import SwiftUI

struct CommandPaletteItem: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case table
        case savedConnection
        case savedQuery
        case action
        case schema
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String?
    let symbolName: String
    let keywords: [String]
    let action: PaletteAction

    static func == (lhs: CommandPaletteItem, rhs: CommandPaletteItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// A type-erased identifier describing what to do when an item is invoked.
/// Kept as a value so commands stay testable without needing closures stored
/// inside an Equatable model.
enum PaletteAction: Hashable {
    case openTable(connectionID: UUID, tableID: String)
    case selectConnection(UUID)
    case runSavedQuery(id: UUID, sql: String, connectionID: UUID)
    case appAction(AppActionKey)
    case focusSchema(connectionID: UUID, schema: String)
}

enum AppActionKey: String, Hashable {
    case newQueryTab
    case toggleSafeMode
    case showDashboard
    case showEditor
    case formatSQL
    case openConnectionForm
}
