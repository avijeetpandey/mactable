//
//  VirtualizedDataGridView.swift
//  mactable
//
//  High-density grid rendering: sticky header with scroll-driven inner
//  shadow, alternating row stripes from AppTheme, SF-Mono cells, double-
//  click inline editing routed through the shared MutationsQueue, and a
//  rich context menu (Copy as JSON, Truncate, Export Row as SQL).
//

import SwiftUI
import AppKit

struct VirtualizedDataGridView: View {
    let result: QueryResult
    let tableName: String?
    @ObservedObject var mutationsQueue: MutationsQueue
    let primaryKeyColumn: String?

    @State private var columnWidths: [UUID: CGFloat] = [:]
    @State private var selectedRowID: UUID?
    @State private var sort: GridSortDescriptor?
    @State private var headerShadowOpacity: Double = 0
    @EnvironmentObject private var toastCenter: ToastCenter

    private let rowHeight: CGFloat = 26
    private let headerHeight: CGFloat = 30
    private let minColumnWidth: CGFloat = 110
    private let maxColumnWidth: CGFloat = 480

    var body: some View {
        ScrollView([.horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .background(.regularMaterial)
                    .overlay(
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [AppTheme.hairline.opacity(0.55), .clear],
                                startPoint: .top, endPoint: .bottom))
                            .frame(height: 6)
                            .opacity(headerShadowOpacity)
                            .allowsHitTesting(false),
                        alignment: .bottom
                    )
                    .zIndex(2)

                ScrollView([.vertical]) {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: proxy.frame(in: .named("grid")).minY
                        )
                    }
                    .frame(height: 0)

                    LazyVStack(spacing: 0) {
                        ForEach(Array(sortedRows.enumerated()), id: \.element.id) { idx, row in
                            renderRow(row, idx: idx)
                        }
                    }
                }
                .coordinateSpace(name: "grid")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    let s = max(0, min(1, -value / 24))
                    if abs(headerShadowOpacity - s) > 0.01 { headerShadowOpacity = s }
                }
            }
        }
        .background(.thinMaterial.opacity(0.4))
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(result.columns) { col in
                GridHeaderCellView(
                    column: col,
                    sortDirection: sort?.columnID == col.id ? sort?.direction : nil,
                    width: width(for: col),
                    onTap: { cycleSort(for: col) }
                )
            }
        }
        .frame(height: headerHeight)
    }

    private func cycleSort(for col: ColumnDescriptor) {
        if let current = sort, current.columnID == col.id {
            sort = current.next()
        } else {
            sort = GridSortDescriptor(columnID: col.id, direction: .ascending)
        }
    }

    // MARK: - Rows

    private var sortedRows: [QueryRow] {
        guard let sort = sort,
              let columnIndex = result.columns.firstIndex(where: { $0.id == sort.columnID }) else {
            return result.rows
        }
        let asc = sort.direction == .ascending
        return result.rows.sorted { lhs, rhs in
            let l = columnIndex < lhs.values.count ? lhs.values[columnIndex] : .null
            let r = columnIndex < rhs.values.count ? rhs.values[columnIndex] : .null
            return asc ? cellLess(l, r) : cellLess(r, l)
        }
    }

    private func cellLess(_ a: CellValue, _ b: CellValue) -> Bool {
        switch (a, b) {
        case (.null, .null): return false
        case (.null, _): return true
        case (_, .null): return false
        case (.integer(let l), .integer(let r)): return l < r
        case (.double(let l), .double(let r)): return l < r
        case (.bool(let l), .bool(let r)): return !l && r
        default: return a.displayString.localizedStandardCompare(b.displayString) == .orderedAscending
        }
    }

    @ViewBuilder
    private func renderRow(_ row: QueryRow, idx: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(result.columns.enumerated()), id: \.element.id) { ci, col in
                let v = ci < row.values.count ? row.values[ci] : CellValue.null
                let pending = mutationsQueue.pending.first(where: { $0.rowID == row.id && $0.columnName == col.name })?.newValue
                EditableGridCellView(
                    value: v,
                    pendingValue: pending,
                    isPrimaryKey: col.name == primaryKeyColumn,
                    onSubmit: { newText in submit(row: row, column: col, original: v, newText: newText) }
                )
                .frame(width: width(for: col), height: rowHeight, alignment: .leading)
                .overlay(
                    Rectangle().fill(AppTheme.hairline.opacity(0.35))
                        .frame(width: 1).frame(maxHeight: .infinity),
                    alignment: .trailing
                )
                .contextMenu { contextMenu(for: row, column: col, value: v) }
            }
        }
        .background(rowBackground(idx: idx, id: row.id))
        .contentShape(Rectangle())
        .onTapGesture { selectedRowID = row.id }
    }

    private func rowBackground(idx: Int, id: UUID) -> some View {
        Group {
            if selectedRowID == id {
                AppTheme.rowSelectedBackdrop
            } else if idx.isMultiple(of: 2) {
                AppTheme.stripeLight
            } else {
                Color.clear
            }
        }
    }

    // MARK: - Editing

    private func submit(row: QueryRow, column: ColumnDescriptor, original: CellValue, newText: String) {
        let parsed = parse(newText, hint: column.typeName)
        guard parsed != original else { return }
        let pkIndex = result.columns.firstIndex(where: { $0.name == primaryKeyColumn })
        let pkValue = pkIndex.flatMap { idx -> CellValue? in
            guard idx < row.values.count else { return nil }
            return row.values[idx]
        }
        let mutation = PendingMutation(
            rowID: row.id,
            columnName: column.name,
            originalValue: original,
            newValue: parsed,
            table: tableName ?? "table",
            primaryKeyColumn: primaryKeyColumn,
            primaryKeyValue: pkValue
        )
        mutationsQueue.enqueue(mutation)
        toastCenter.push("Edit queued · \(mutation.summary)", kind: .info)
    }

    private func parse(_ text: String, hint: String) -> CellValue {
        if text.isEmpty || text.uppercased() == "NULL" { return .null }
        return CellValue.from(string: text, typeHint: hint)
    }

    // MARK: - Context menu

    @ViewBuilder
    private func contextMenu(for row: QueryRow, column: ColumnDescriptor, value: CellValue) -> some View {
        Button("Copy Value") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value.displayString, forType: .string)
            toastCenter.push("Copied value", kind: .info)
        }
        Button("Copy Value as JSON") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value.jsonRepresentation, forType: .string)
            toastCenter.push("Copied JSON", kind: .info)
        }
        Button("Copy Row as JSON") {
            let json = ExportService.toJSONObject(row: row, columns: result.columns)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(json, forType: .string)
            toastCenter.push("Copied row JSON", kind: .info)
        }
        Divider()
        Button("Export Row as SQL") {
            let stmt = ExportService.toInsertSQL(row: row, columns: result.columns, table: tableName ?? "table")
            ExportService.savePanel(suggested: "row.sql", content: stmt)
        }
        Button("Export Selection to CSV") {
            ExportService.savePanel(suggested: "results.csv", content: ExportService.toCSV(result))
        }
        Divider()
        Button("Truncate Table…", role: .destructive) {
            NotificationCenter.default.post(
                name: .destructiveTruncate,
                object: tableName ?? "table"
            )
        }
    }

    private func width(for col: ColumnDescriptor) -> CGFloat {
        if let w = columnWidths[col.id] { return w }
        let estimate = CGFloat(col.name.count * 9 + 48)
        return min(maxColumnWidth, max(minColumnWidth, estimate))
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension Notification.Name {
    static let destructiveTruncate = Notification.Name("mactable.destructiveTruncate")
}
