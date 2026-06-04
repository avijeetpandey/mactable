//
//  SchemaDiffTests.swift
//  mactableTests
//

import XCTest
@testable import mactable

final class SchemaDiffTests: XCTestCase {

    private func t(_ schema: String, _ name: String, rows: Int? = nil) -> TableInfo {
        TableInfo(id: "\(schema).\(name)", schema: schema, name: name, kind: .table, estimatedRows: rows)
    }

    func testAddedAndRemovedDetected() {
        let left  = [t("public", "movies", rows: 10), t("public", "actors")]
        let right = [t("public", "movies", rows: 10), t("public", "directors")]
        let deltas = SchemaDiff.compare(left: left, right: right)
        let kinds = deltas.map(\.kind)
        XCTAssertTrue(kinds.contains(.added))
        XCTAssertTrue(kinds.contains(.removed))
        XCTAssertTrue(kinds.contains(.unchanged))
    }

    func testModifiedWhenRowCountDiffers() {
        let left  = [t("public", "movies", rows: 100)]
        let right = [t("public", "movies", rows: 250)]
        let deltas = SchemaDiff.compare(left: left, right: right)
        XCTAssertEqual(deltas.first?.kind, .modified)
    }

    func testMigrationScriptContainsExpectedClauses() {
        let left  = [t("public", "old")]
        let right = [t("public", "new")]
        let deltas = SchemaDiff.compare(left: left, right: right)
        let script = SchemaDiff.migrationScript(deltas: deltas)
        XCTAssertTrue(script.contains("DROP TABLE"))
        XCTAssertTrue(script.contains("CREATE TABLE"))
    }
}
