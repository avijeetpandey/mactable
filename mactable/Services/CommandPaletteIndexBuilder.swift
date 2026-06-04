//
//  CommandPaletteIndexBuilder.swift
//  mactable
//
//  Pure transformation that flattens the live application state — saved
//  connections, active sessions with their schema, persisted snippets, and
//  built-in actions — into a `CommandPaletteIndex`.
//

import Foundation

enum CommandPaletteIndexBuilder {

    static func build(savedConnections: [SavedConnection],
                      sessions: [UUID: ConnectionSession],
                      savedQueries: [SavedQuery]) -> CommandPaletteIndex {
        var items: [CommandPaletteItem] = []
        items.append(contentsOf: builtInActions())
        items.append(contentsOf: connectionItems(from: savedConnections))
        items.append(contentsOf: tableItems(savedConnections: savedConnections, sessions: sessions))
        items.append(contentsOf: savedQueryItems(savedQueries: savedQueries, savedConnections: savedConnections))
        return CommandPaletteIndex(items: items)
    }

    // MARK: - Sections

    private static func builtInActions() -> [CommandPaletteItem] {
        return [
            CommandPaletteItem(
                id: "action.newQueryTab",
                kind: .action,
                title: "New Query Tab",
                subtitle: "Open a fresh SQL editor tab",
                symbolName: "plus.square.on.square",
                keywords: ["new", "tab", "editor", "query"],
                action: .appAction(.newQueryTab)
            ),
            CommandPaletteItem(
                id: "action.toggleSafe",
                kind: .action,
                title: "Toggle Safe Mode",
                subtitle: "Require explicit commit for destructive queries",
                symbolName: "lock.shield",
                keywords: ["safe", "mode", "lock", "production"],
                action: .appAction(.toggleSafeMode)
            ),
            CommandPaletteItem(
                id: "action.showDashboard",
                kind: .action,
                title: "Show Dashboard",
                subtitle: "Switch the workspace to the metrics dashboard",
                symbolName: "chart.bar.xaxis",
                keywords: ["dashboard", "metrics", "stats"],
                action: .appAction(.showDashboard)
            ),
            CommandPaletteItem(
                id: "action.showEditor",
                kind: .action,
                title: "Show SQL Editor",
                subtitle: "Switch the workspace to the query editor",
                symbolName: "terminal",
                keywords: ["sql", "editor", "query"],
                action: .appAction(.showEditor)
            ),
            CommandPaletteItem(
                id: "action.formatSQL",
                kind: .action,
                title: "Format SQL",
                subtitle: "Pretty-print the active editor buffer",
                symbolName: "wand.and.stars",
                keywords: ["format", "pretty", "indent", "sql"],
                action: .appAction(.formatSQL)
            ),
            CommandPaletteItem(
                id: "action.addConnection",
                kind: .action,
                title: "Add Connection…",
                subtitle: "Open the connection form",
                symbolName: "plus.circle",
                keywords: ["new", "connection", "add"],
                action: .appAction(.openConnectionForm)
            )
        ]
    }

    private static func connectionItems(from connections: [SavedConnection]) -> [CommandPaletteItem] {
        connections.map { saved in
            CommandPaletteItem(
                id: "connection.\(saved.id.uuidString)",
                kind: .savedConnection,
                title: saved.name,
                subtitle: "\(saved.kind.displayName) · \(saved.host):\(saved.port)",
                symbolName: saved.kind.symbolName,
                keywords: [saved.kind.displayName, saved.host, "connection"],
                action: .selectConnection(saved.id)
            )
        }
    }

    private static func tableItems(savedConnections: [SavedConnection],
                                   sessions: [UUID: ConnectionSession]) -> [CommandPaletteItem] {
        var out: [CommandPaletteItem] = []
        for saved in savedConnections {
            guard let session = sessions[saved.id] else { continue }
            for table in session.tables {
                out.append(CommandPaletteItem(
                    id: "table.\(saved.id.uuidString).\(table.id)",
                    kind: .table,
                    title: table.name,
                    subtitle: "\(saved.name) · \(table.schema)",
                    symbolName: table.kind.symbolName,
                    keywords: [table.schema, saved.name, table.kind.rawValue],
                    action: .openTable(connectionID: saved.id, tableID: table.id)
                ))
            }
        }
        return out
    }

    private static func savedQueryItems(savedQueries: [SavedQuery],
                                        savedConnections: [SavedConnection]) -> [CommandPaletteItem] {
        let connectionByID = Dictionary(uniqueKeysWithValues: savedConnections.map { ($0.id, $0) })
        return savedQueries.map { sq in
            let owner = connectionByID[sq.connectionID]?.name ?? "Unassigned"
            return CommandPaletteItem(
                id: "savedQuery.\(sq.id.uuidString)",
                kind: .savedQuery,
                title: sq.name,
                subtitle: "Saved query · \(owner)",
                symbolName: "doc.text.magnifyingglass",
                keywords: ["query", "saved", owner],
                action: .runSavedQuery(id: sq.id, sql: sq.sql, connectionID: sq.connectionID)
            )
        }
    }
}
