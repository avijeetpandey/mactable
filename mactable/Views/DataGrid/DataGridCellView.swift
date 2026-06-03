//
//  DataGridCellView.swift
//  mactable
//

import SwiftUI
import AppKit

struct DataGridCellView: View {
    let value: CellValue
    let row: QueryRow
    let columns: [ColumnDescriptor]

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            if value.isNull {
                Text("NULL")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.10)))
            } else {
                Text(value.displayString)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
        .contextMenu {
            Button("Copy Value") { copyToPasteboard(value.displayString) }
            Button("Copy as JSON") { copyToPasteboard(ExportService.toJSON(row, columns: columns)) }
            Divider()
            Button("Export Row to CSV") {
                let r = QueryResult(columns: columns, rows: [row], rowsAffected: 1, executionTime: 0, notice: nil)
                ExportService.savePanel(suggested: "row.csv", content: ExportService.toCSV(r))
            }
        }
    }

    private func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
