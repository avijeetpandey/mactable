//
//  CRDTDocumentTests.swift
//  mactableTests
//

import XCTest
@testable import mactable

final class CRDTDocumentTests: XCTestCase {

    func testLocalInsertProducesText() {
        let doc = CRDTDocument()
        doc.localInsert(character: "S", atIndex: 0)
        doc.localInsert(character: "E", atIndex: 1)
        doc.localInsert(character: "L", atIndex: 2)
        XCTAssertEqual(doc.text, "SEL")
    }

    func testLocalDeleteTombstones() {
        let doc = CRDTDocument()
        doc.localInsert(character: "A", atIndex: 0)
        doc.localInsert(character: "B", atIndex: 1)
        doc.localDelete(atIndex: 0)
        XCTAssertEqual(doc.text, "B")
    }

    func testConcurrentInsertsConverge() {
        let docA = CRDTDocument()
        let docB = CRDTDocument()
        let d1 = docA.localInsert(character: "A", atIndex: 0)
        let d2 = docB.localInsert(character: "B", atIndex: 0)
        // Apply each side's delta to the other.
        docA.applyRemote(d2)
        docB.applyRemote(d1)
        // Both replicas converge to the same string regardless of order.
        XCTAssertEqual(docA.text, docB.text)
    }
}
