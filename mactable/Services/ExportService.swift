//
//  ExportService.swift
//  mactable
//

import Foundation
import AppKit

enum ExportService {
    static func toCSV(_ result: QueryResult) -> String {
        var lines: [String] = []
        lines.append(result.columns.map { csvEscape($0.name) }.joined(separator: ","))
        for row in result.rows {
            let cells = row.values.map { v -> String in
                if case .null = v { return "" }
                return csvEscape(v.displayString)
            }
            lines.append(cells.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func toJSON(_ row: QueryRow, columns: [ColumnDescriptor]) -> String {
        var pairs: [String] = []
        for (i, col) in columns.enumerated() where i < row.values.count {
            pairs.append("\"\(col.name)\": \(row.values[i].jsonRepresentation)")
        }
        return "{ \(pairs.joined(separator: ", ")) }"
    }

    /// Backwards-compatible alias used by the new context menu.
    static func toJSONObject(row: QueryRow, columns: [ColumnDescriptor]) -> String {
        toJSON(row, columns: columns)
    }

    /// Compile a single row into a parameterised INSERT statement suitable
    /// for re-running against the same table.
    static func toInsertSQL(row: QueryRow, columns: [ColumnDescriptor], table: String) -> String {
        let cols = columns.map { "\"\($0.name)\"" }.joined(separator: ", ")
        let vals = zip(row.values, columns).map { value, _ in SQLLiteralFormatter.format(value) }.joined(separator: ", ")
        return "INSERT INTO \"\(table)\" (\(cols)) VALUES (\(vals));"
    }

    static func toSQLDump(tableName: String, result: QueryResult) -> String {
        var lines: [String] = []
        let cols = result.columns.map { "\"\($0.name)\"" }.joined(separator: ", ")
        for row in result.rows {
            let vals = row.values.map { v -> String in
                switch v {
                case .null: return "NULL"
                case .integer(let i): return String(i)
                case .double(let d): return String(d)
                case .bool(let b): return b ? "TRUE" : "FALSE"
                default: return "'" + v.displayString.replacingOccurrences(of: "'", with: "''") + "'"
                }
            }.joined(separator: ", ")
            lines.append("INSERT INTO \(tableName) (\(cols)) VALUES (\(vals));")
        }
        return lines.joined(separator: "\n")
    }

    static func savePanel(suggested: String, content: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggested
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
