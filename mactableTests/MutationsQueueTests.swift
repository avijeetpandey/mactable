//
//  MutationsQueueTests.swift
//  mactableTests
//

import XCTest
@testable import mactable

@MainActor
final class MutationsQueueTests: XCTestCase {

    private func mutation(row: UUID = UUID(), column: String = "title", new: CellValue = .string("New")) -> PendingMutation {
        PendingMutation(rowID: row, columnName: column,
                        originalValue: .string("Old"),
                        newValue: new,
                        table: "movies",
                        primaryKeyColumn: "id",
                        primaryKeyValue: .integer(42))
    }

    func testEnqueueReplacesPreviousEditOnSameCell() {
        let queue = MutationsQueue()
        let row = UUID()
        queue.enqueue(mutation(row: row, new: .string("v1")))
        queue.enqueue(mutation(row: row, new: .string("v2")))
        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.pending.first?.newValue, .string("v2"))
    }

    func testCompileGeneratesParameterisedUpdate() {
        let queue = MutationsQueue()
        queue.enqueue(mutation(new: .string("Inception")))
        let sql = queue.compileSQL()
        XCTAssertEqual(sql.count, 1)
        XCTAssertTrue(sql[0].contains("UPDATE \"movies\" SET \"title\" = 'Inception'"))
        XCTAssertTrue(sql[0].contains("WHERE \"id\" = 42"))
    }

    func testCompileEscapesSingleQuotes() {
        let queue = MutationsQueue()
        queue.enqueue(mutation(new: .string("It's a test")))
        XCTAssertTrue(queue.compileSQL().first!.contains("'It''s a test'"))
    }

    func testRevertRemovesMutation() {
        let queue = MutationsQueue()
        let m = mutation()
        queue.enqueue(m)
        queue.revert(id: queue.pending[0].id)
        XCTAssertTrue(queue.isEmpty)
    }
}
