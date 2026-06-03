//
//  QueryResult.swift
//  mactable
//

import Foundation

struct QueryResult: Hashable {
    let columns: [ColumnDescriptor]
    let rows: [QueryRow]
    let rowsAffected: Int
    let executionTime: TimeInterval
    let notice: String?

    static let empty = QueryResult(columns: [], rows: [], rowsAffected: 0, executionTime: 0, notice: nil)

    var isEmpty: Bool { rows.isEmpty && columns.isEmpty }
}

struct ColumnDescriptor: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let typeName: String
    let isNullable: Bool

    enum CodingKeys: String, CodingKey { case name, typeName, isNullable }
}

struct QueryRow: Hashable, Identifiable {
    let id: UUID
    var values: [CellValue]

    init(id: UUID = UUID(), values: [CellValue]) {
        self.id = id
        self.values = values
    }
}
