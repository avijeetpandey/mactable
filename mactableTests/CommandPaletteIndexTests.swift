//
//  CommandPaletteIndexTests.swift
//  mactableTests
//
//  Verifies fuzzy ranking semantics and section composition.
//

import XCTest
@testable import mactable

final class CommandPaletteIndexTests: XCTestCase {

    private func makeItem(id: String, title: String, kind: CommandPaletteItem.Kind = .action, keywords: [String] = []) -> CommandPaletteItem {
        CommandPaletteItem(id: id, kind: kind, title: title, subtitle: nil,
                           symbolName: "circle", keywords: keywords,
                           action: .appAction(.newQueryTab))
    }

    func testEmptyQueryReturnsAllItems() {
        let index = CommandPaletteIndex(items: [makeItem(id: "a", title: "Alpha"),
                                                makeItem(id: "b", title: "Bravo")])
        XCTAssertEqual(index.search("").count, 2)
    }

    func testExactPrefixOutranksSubstring() {
        let items = [
            makeItem(id: "1", title: "Movies"),
            makeItem(id: "2", title: "Comovie")
        ]
        let index = CommandPaletteIndex(items: items)
        let results = index.search("mov")
        XCTAssertEqual(results.first?.id, "1")
    }

    func testKeywordMatchSurvivesWhenTitleMisses() {
        let items = [
            makeItem(id: "a", title: "Toggle Safe Mode", keywords: ["lock", "production"]),
            makeItem(id: "b", title: "Format SQL", keywords: ["pretty"])
        ]
        let index = CommandPaletteIndex(items: items)
        let results = index.search("lock")
        XCTAssertEqual(results.first?.id, "a")
    }

    func testSubsequenceFallback() {
        let items = [makeItem(id: "1", title: "show dashboard")]
        let index = CommandPaletteIndex(items: items)
        let results = index.search("shdsh")
        XCTAssertEqual(results.count, 1)
    }
}
