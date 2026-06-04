//
//  ResultsTableView.swift
//  mactable
//

import SwiftUI
import AppKit

struct ResultsTableView: View {
    let result: QueryResult
    let errorMessage: String?
    let tableName: String?
    let primaryKeyColumn: String?
    @ObservedObject var mutationsQueue: MutationsQueue
    let onCommit: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(result.isEmpty ? "Results" : "\(result.rows.count) rows · \(result.columns.count) columns")
                    .font(AppTypography.metadata(11).weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryLabel)
                Spacer()
                if !result.rows.isEmpty {
                    Button {
                        ExportService.savePanel(suggested: "results.csv", content: ExportService.toCSV(result))
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(HoverableButtonStyle(tint: .secondary))
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            Divider().opacity(0.2)
            if let err = errorMessage {
                EmptyStateView(symbol: "xmark.octagon", title: "Query Error", message: err)
            } else if result.isEmpty {
                EmptyStateView(symbol: "tray.fill", title: "No Results",
                               message: "Run a query to view results.")
            } else {
                ZStack(alignment: .bottom) {
                    VirtualizedDataGridView(
                        result: result,
                        tableName: tableName,
                        mutationsQueue: mutationsQueue,
                        primaryKeyColumn: primaryKeyColumn
                    )
                    if !mutationsQueue.isEmpty {
                        PendingCommitBarView(
                            queue: mutationsQueue,
                            onCommit: onCommit,
                            onDiscard: onDiscard
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.73), value: mutationsQueue.isEmpty)
            }
        }
    }
}
