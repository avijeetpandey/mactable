//
//  SchemaTreeBuilder.swift
//  mactable
//
//  Pure transformation: derives the navigator tree from a ConnectionSession.
//  Side-effect free so it can be unit-tested independently of any driver.
//

import Foundation

enum SchemaTreeBuilder {

    /// Build a single-rooted tree for the given connection session.
    /// The returned root represents the connection itself and contains
    /// one child per schema, each containing one child per table/view.
    static func build(for session: ConnectionSession) -> SchemaNode {
        let schemaGroups = Dictionary(grouping: session.tables, by: { $0.schema })
        let schemaNodes: [SchemaNode] = schemaGroups
            .map { (schema, tables) in
                let tableNodes = tables
                    .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
                    .map { table -> SchemaNode in
                        SchemaNode(
                            id: "\(session.id.uuidString):\(schema):\(table.name)",
                            kind: .table(table.kind),
                            title: table.name,
                            subtitle: subtitle(for: table),
                            symbolName: symbolName(for: table.kind),
                            tableInfo: table,
                            children: []
                        )
                    }

                return SchemaNode(
                    id: "\(session.id.uuidString):\(schema.isEmpty ? "_" : schema)",
                    kind: .schema,
                    title: schema.isEmpty ? "default" : schema,
                    subtitle: "\(tableNodes.count) object\(tableNodes.count == 1 ? "" : "s")",
                    symbolName: "folder.fill",
                    tableInfo: nil,
                    children: tableNodes
                )
            }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }

        return SchemaNode(
            id: "\(session.id.uuidString):root",
            kind: .connection,
            title: session.config.name,
            subtitle: "\(session.config.kind.displayName) · \(session.config.host):\(session.config.port)",
            symbolName: session.config.kind.symbolName,
            tableInfo: nil,
            children: schemaNodes
        )
    }

    private static func subtitle(for table: TableInfo) -> String? {
        if let rows = table.estimatedRows {
            return "~\(rows) rows"
        }
        return nil
    }

    /// Per-spec mapping: tables → `tablecells`, views → `eye`.
    private static func symbolName(for kind: TableKind) -> String {
        switch kind {
        case .table:            return "tablecells"
        case .view:             return "eye"
        case .materializedView: return "eye.fill"
        case .collection:       return "doc.text.fill"
        }
    }
}
