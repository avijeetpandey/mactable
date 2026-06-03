//
//  VirtualizedDataGridView.swift
//  mactable
//
//  Native SwiftUI grid that virtualizes rows for performance with millions of rows.
//

import SwiftUI

struct VirtualizedDataGridView: View {
    let result: QueryResult
    @State private var columnWidths: [UUID: CGFloat] = [:]
    @State private var selectedRowID: UUID?

    private let rowHeight: CGFloat = 26
    private let minColumnWidth: CGFloat = 110
    private let maxColumnWidth: CGFloat = 480

    var body: some View {
        ScrollView([.horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider().opacity(0.3)
                ScrollView([.vertical]) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(result.rows.enumerated()), id: \.element.id) { idx, row in
                            HStack(spacing: 0) {
                                ForEach(Array(result.columns.enumerated()), id: \.element.id) { ci, col in
                                    let v = ci < row.values.count ? row.values[ci] : .null
                                    DataGridCellView(value: v, row: row, columns: result.columns)
                                        .frame(width: width(for: col), height: rowHeight, alignment: .leading)
                                        .padding(.horizontal, 10)
                                        .overlay(
                                            Rectangle().fill(Color.secondary.opacity(0.10))
                                                .frame(width: 1).frame(maxHeight: .infinity),
                                            alignment: .trailing
                                        )
                                }
                            }
                            .background(rowBackground(idx: idx, id: row.id))
                            .contentShape(Rectangle())
                            .onTapGesture { selectedRowID = row.id }
                        }
                    }
                }
            }
        }
        .background(.thinMaterial.opacity(0.4))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(result.columns) { col in
                HStack(spacing: 4) {
                    Text(col.name)
                        .font(.system(.caption, design: .monospaced, weight: .semibold))
                        .lineLimit(1)
                    Text(col.typeName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(width: width(for: col), height: 28, alignment: .leading)
                .overlay(
                    Rectangle().fill(Color.secondary.opacity(0.20))
                        .frame(width: 1).frame(maxHeight: .infinity),
                    alignment: .trailing
                )
            }
        }
        .background(.regularMaterial)
    }

    private func width(for col: ColumnDescriptor) -> CGFloat {
        if let w = columnWidths[col.id] { return w }
        let estimate = CGFloat(col.name.count * 9 + 48)
        return min(maxColumnWidth, max(minColumnWidth, estimate))
    }

    private func rowBackground(idx: Int, id: UUID) -> some View {
        Group {
            if selectedRowID == id {
                Color.accentColor.opacity(0.15)
            } else if idx.isMultiple(of: 2) {
                Color.secondary.opacity(0.04)
            } else {
                Color.clear
            }
        }
    }
}
