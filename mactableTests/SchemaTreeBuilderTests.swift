//
//  SchemaTreeBuilderTests.swift
//  mactableTests
//
//  Verifies the pure tree transformation from ConnectionSession into a
//  hierarchical SchemaNode model used by the sidebar navigator.
//

import XCTest
@testable import mactable

@MainActor
final class SchemaTreeBuilderTests: XCTestCase {

    private func makeSession(tables: [TableInfo]) -> ConnectionSession {
        let config = ConnectionConfig(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Local PG",
            kind: .postgres,
            host: "127.0.0.1",
            port: 5432,
            username: "mactable",
            database: "movies",
            useTLS: false
        )
        let session = ConnectionSession(config: config)
        session.tables = tables
        return session
    }

    private func table(_ schema: String, _ name: String, _ kind: TableKind, rows: Int? = nil) -> TableInfo {
        TableInfo(id: "\(schema).\(name)", schema: schema, name: name, kind: kind, estimatedRows: rows)
    }

    func testBuildGroupsTablesBySchema() {
        let tables: [TableInfo] = [
            table("public", "movies", .table, rows: 100),
            table("public", "actors", .table, rows: 50),
            table("analytics", "daily_stats", .view)
        ]
        let session = makeSession(tables: tables)

        let root = SchemaTreeBuilder.build(for: session)

        XCTAssertEqual(root.kind, .connection)
        XCTAssertEqual(root.title, "Local PG")
        XCTAssertEqual(root.children.count, 2, "Two distinct schemas should produce two child nodes")

        let schemaTitles = root.children.map(\.title)
        XCTAssertEqual(schemaTitles, ["analytics", "public"], "Schemas must be alphabetised")

        let publicSchema = root.children.first(where: { $0.title == "public" })!
        XCTAssertEqual(publicSchema.kind, .schema)
        XCTAssertEqual(publicSchema.children.map(\.title), ["actors", "movies"])
    }

    func testTableSymbolMappingMatchesPhase1Spec() {
        let tables: [TableInfo] = [
            table("s", "t1", .table),
            table("s", "v1", .view),
            table("s", "mv1", .materializedView),
            table("s", "c1", .collection)
        ]
        let session = makeSession(tables: tables)

        let root = SchemaTreeBuilder.build(for: session)
        let schema = root.children[0]
        let bySymbol = Dictionary(uniqueKeysWithValues: schema.children.map { ($0.title, $0.symbolName) })

        XCTAssertEqual(bySymbol["t1"], "tablecells")
        XCTAssertEqual(bySymbol["v1"], "eye")
        XCTAssertEqual(bySymbol["mv1"], "eye.fill")
        XCTAssertEqual(bySymbol["c1"], "doc.text.fill")
    }

    func testEmptySessionStillProducesConnectionRoot() {
        let session = makeSession(tables: [])
        let root = SchemaTreeBuilder.build(for: session)

        XCTAssertEqual(root.kind, .connection)
        XCTAssertTrue(root.children.isEmpty)
        XCTAssertEqual(root.subtitle, "PostgreSQL · 127.0.0.1:5432")
    }

    func testRowCountSubtitleFormatting() {
        let tables = [table("public", "movies", .table, rows: 1234)]
        let session = makeSession(tables: tables)
        let root = SchemaTreeBuilder.build(for: session)
        let table = root.children[0].children[0]

        XCTAssertEqual(table.subtitle, "~1234 rows")
    }
}
