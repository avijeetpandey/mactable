//
//  PendingMutation.swift
//  mactable
//
//  Represents a single uncommitted cell edit captured by the production
//  Safe-Mode guard. Mutations sit in `MutationsQueue` until the user
//  clicks "Commit Changes" — at which point the queue compiles them into
//  parameterised UPDATE statements and dispatches them to the driver.
//

import Foundation

struct PendingMutation: Identifiable, Hashable {
    let id: UUID
    let rowID: UUID
    let columnName: String
    let originalValue: CellValue
    let newValue: CellValue
    let table: String
    let primaryKeyColumn: String?
    let primaryKeyValue: CellValue?
    let createdAt: Date

    init(rowID: UUID,
         columnName: String,
         originalValue: CellValue,
         newValue: CellValue,
         table: String,
         primaryKeyColumn: String?,
         primaryKeyValue: CellValue?) {
        self.id = UUID()
        self.rowID = rowID
        self.columnName = columnName
        self.originalValue = originalValue
        self.newValue = newValue
        self.table = table
        self.primaryKeyColumn = primaryKeyColumn
        self.primaryKeyValue = primaryKeyValue
        self.createdAt = Date()
    }

    /// Human-readable summary used in the commit confirmation alert.
    var summary: String {
        let pk = primaryKeyValue?.displayString ?? "row \(rowID.uuidString.prefix(6))"
        return "\(table).\(columnName) → \(newValue.displayString) [\(primaryKeyColumn ?? "id")=\(pk)]"
    }
}
