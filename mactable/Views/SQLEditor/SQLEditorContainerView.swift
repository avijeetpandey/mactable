//
//  SQLEditorContainerView.swift
//  mactable
//

import SwiftUI

struct SQLEditorContainerView: View {
    @ObservedObject var session: ConnectionSession
    @StateObject private var viewModel: QueryEditorViewModel
    @EnvironmentObject private var toastCenter: ToastCenter
    @State private var splitFraction: CGFloat = 0.42

    init(session: ConnectionSession) {
        self.session = session
        _viewModel = StateObject(wrappedValue: QueryEditorViewModel(session: session))
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    SQLCodeView(text: $viewModel.sql,
                                keywords: SQLKeywords.list(for: session.config.kind),
                                tableNames: session.tables.map { $0.name })
                        .frame(height: max(120, geo.size.height * splitFraction))
                    SQLEditorPillBarView(viewModel: viewModel)
                        .padding(.top, 8)
                }
                Divider().opacity(0.2)
                QueryTimeTravelScrubberView(viewModel: viewModel)
                Divider().opacity(0.2)
                ResultsTableView(
                    result: viewModel.result,
                    errorMessage: viewModel.errorMessage,
                    tableName: viewModel.currentTable,
                    primaryKeyColumn: viewModel.primaryKeyColumn,
                    mutationsQueue: viewModel.mutationsQueue,
                    onCommit: { viewModel.commitMutations() },
                    onDiscard: { viewModel.discardMutations() }
                )
            }
        }
        .onAppear { viewModel.toastCenter = toastCenter }
        .onReceive(NotificationCenter.default.publisher(for: .executeQuery)) { _ in viewModel.run() }
        .onReceive(NotificationCenter.default.publisher(for: .formatSQL)) { _ in viewModel.formatSQL() }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSafeMode)) { _ in viewModel.toggleSafeMode() }
        .onReceive(NotificationCenter.default.publisher(for: .runSavedQuery)) { note in
            if let sql = note.object as? String {
                viewModel.sql = sql
                viewModel.run()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .destructiveTruncate)) { note in
            if let table = note.object as? String {
                viewModel.sql = "TRUNCATE TABLE \"\(table)\";"
            }
        }
        .alert("Confirm destructive query",
               isPresented: Binding(
                get: { viewModel.pendingDestructiveSQL != nil },
                set: { if !$0 { viewModel.cancelDestructive() } }
               )) {
            Button("Cancel", role: .cancel) { viewModel.cancelDestructive() }
            Button("Commit Changes", role: .destructive) { viewModel.confirmDestructive() }
        } message: {
            Text(viewModel.pendingDestructiveSQL ?? "")
                .font(.system(.body, design: .monospaced))
        }
    }
}
