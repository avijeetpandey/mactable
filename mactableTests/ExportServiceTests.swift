//
//  ExportServiceTests.swift
//  mactableTests
//

import Testing
import Foundation
@testable import mactable

struct ExportServiceTests {
    private func makeResult() -> QueryResult {
        let cols = [
            ColumnDescriptor(name: "id", typeName: "integer", isNullable: false),
            ColumnDescriptor(name: "name", typeName: "text", isNullable: true)
        ]
        let rows = [
            QueryRow(values: [.integer(1), .string("Hello, World")]),
            QueryRow(values: [.integer(2), .null])
        ]
        return QueryResult(columns: cols, rows: rows, rowsAffected: 2, executionTime: 0, notice: nil)
    }

    @Test func csvEscapesCommas() {
        let csv = ExportService.toCSV(makeResult())
        let lines = csv.split(separator: "\n").map(String.init)
        #expect(lines.first == "id,name")
        #expect(lines[1].contains("\"Hello, World\""))
    }

    @Test func jsonRepresentation() {
        let result = makeResult()
        let json = ExportService.toJSON(result.rows[0], columns: result.columns)
        #expect(json.contains("\"id\": 1"))
        #expect(json.contains("\"name\": \"Hello, World\""))
    }

    @Test func sqlDumpRendersInsert() {
        let dump = ExportService.toSQLDump(tableName: "users", result: makeResult())
        #expect(dump.contains("INSERT INTO users"))
        #expect(dump.contains("NULL"))
    }
}
