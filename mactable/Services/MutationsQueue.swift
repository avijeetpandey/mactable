//
//  MutationsQueue.swift
//  mactable
//
//  Thread-safe @MainActor queue that buffers Safe-Mode-blocked cell edits
//  until the user explicitly commits. Compiles the queue into a list of
//  parameterised SQL strings ready to be sent to a `DatabaseDriver`.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MutationsQueue: ObservableObject {
    @Published private(set) var pending: [PendingMutation] = []

    var isEmpty: Bool { pending.isEmpty }
    var count: Int { pending.count }

    func enqueue(_ mutation: PendingMutation) {
        // If a previous edit on the same row+column exists, replace it
        // (the user is iterating on the same cell value pre-commit).
        if let idx = pending.firstIndex(where: { $0.rowID == mutation.rowID && $0.columnName == mutation.columnName }) {
            pending[idx] = mutation
        } else {
            pending.append(mutation)
        }
    }

    func revert(id: UUID) {
        pending.removeAll { $0.id == id }
    }

    func clear() {
        pending.removeAll()
    }

    /// Compile every queued mutation into a parameterised SQL statement.
    /// Falls back to a NULL where clause if no primary key is known so
    /// callers can decide whether the statement is safe to execute.
    func compileSQL(quoting: SQLQuoting = .doubleQuote) -> [String] {
        pending.map { mutation in
            let column = quoting.quote(mutation.columnName)
            let table = quoting.quote(mutation.table)
            let assignment = "\(column) = \(SQLLiteralFormatter.format(mutation.newValue))"
            let whereClause: String
            if let pk = mutation.primaryKeyColumn, let pkValue = mutation.primaryKeyValue {
                whereClause = "\(quoting.quote(pk)) = \(SQLLiteralFormatter.format(pkValue))"
            } else {
                whereClause = "TRUE /* missing primary key — review before running */"
            }
            return "UPDATE \(table) SET \(assignment) WHERE \(whereClause);"
        }
    }
}

enum SQLQuoting {
    case doubleQuote
    case backtick

    func quote(_ identifier: String) -> String {
        switch self {
        case .doubleQuote: return "\"\(identifier.replacingOccurrences(of: "\"", with: "\"\""))\""
        case .backtick:    return "`\(identifier.replacingOccurrences(of: "`", with: "``"))`"
        }
    }
}
