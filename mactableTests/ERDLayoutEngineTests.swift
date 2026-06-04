//
//  ERDLayoutEngineTests.swift
//  mactableTests
//

import XCTest
@testable import mactable

final class ERDLayoutEngineTests: XCTestCase {

    private func node(_ name: String, foreign: String? = nil) -> ERDNode {
        let cols: [ERDColumn] = [
            ERDColumn(name: "id", typeName: "uuid", isPrimary: true, foreignReference: nil),
            ERDColumn(name: "fk", typeName: "uuid", isPrimary: false,
                      foreignReference: foreign.map { ERDForeignReference(targetTable: $0, targetColumn: "id") })
        ]
        return ERDNode(id: "public.\(name)", table: name, schema: "public",
                       columns: cols, position: .zero, size: ERDNode.defaultSize)
    }

    func testLayoutPositionsDoNotOverlap() {
        let nodes = [node("a"), node("b"), node("c"), node("d", foreign: "a")]
        let laid = ERDLayoutEngine.layout(nodes)
        let positions = laid.map { $0.position }
        XCTAssertEqual(Set(positions).count, positions.count)
    }

    func testReferencedTablesPlacedFirst() {
        // 'a' is referenced by 'b' so it should sort earlier in the grid.
        let nodes = [node("b", foreign: "a"), node("a")]
        let laid = ERDLayoutEngine.layout(nodes)
        let aIdx = laid.firstIndex(where: { $0.table == "a" })!
        let bIdx = laid.firstIndex(where: { $0.table == "b" })!
        XCTAssertLessThan(aIdx, bIdx)
    }
}
