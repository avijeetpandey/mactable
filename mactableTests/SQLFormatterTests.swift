//
//  SQLFormatterTests.swift
//  mactableTests
//

import XCTest
@testable import mactable

final class SQLFormatterTests: XCTestCase {

    func testInsertsNewlinesAtMajorClauses() {
        let formatted = SQLFormatter.format("SELECT * FROM movies WHERE year > 2000 ORDER BY year")
        XCTAssertTrue(formatted.contains("\nFROM"))
        XCTAssertTrue(formatted.contains("\nWHERE"))
        XCTAssertTrue(formatted.contains("\nORDER BY"))
    }

    func testCollapsesExtraWhitespace() {
        let formatted = SQLFormatter.format("SELECT   * \n\n   FROM   movies")
        XCTAssertFalse(formatted.contains("   "))
    }
}

final class SQLAnalyzerTests: XCTestCase {
    func testTableNameFromSelect() {
        XCTAssertEqual(SQLAnalyzer.tableName(in: "SELECT * FROM public.movies WHERE 1=1"), "movies")
    }

    func testTableNameFromUpdate() {
        XCTAssertEqual(SQLAnalyzer.tableName(in: "UPDATE \"movies\" SET title = 'x'"), "movies")
    }

    func testTableNameNilWhenAbsent() {
        XCTAssertNil(SQLAnalyzer.tableName(in: "SHOW TABLES"))
    }
}
