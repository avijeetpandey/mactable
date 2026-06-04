//
//  SchemaDiffView.swift
//  mactable
//
//  Side-by-side schema comparison terminal. The left pane is fixed to the
//  active session; the right pane is selectable from any other live
//  ConnectionSession in the store. Deltas are colour-coded per Phase 6
//  spec (green = added, red = removed, amber = modified).
//

import SwiftUI

struct SchemaDiffView: View {
    @ObservedObject var session: ConnectionSession
    @EnvironmentObject private var connectionStore: ConnectionStore
    @State private var rightSessionID: UUID?
    @State private var migrationVisible: Bool = false

    private var rightSession: ConnectionSession? {
        guard let id = rightSessionID else { return nil }
        return connectionStore.session(for: id)
    }

    private var deltas: [SchemaDelta] {
        guard let r = rightSession else { return [] }
        return SchemaDiff.compare(left: session.tables, right: r.tables)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider().opacity(0.2)
            HStack(spacing: 0) {
                pane(title: session.config.name, tables: session.tables, side: .left)
                Divider().opacity(0.2)
                pane(title: rightSession?.config.name ?? "Pick a target…", tables: rightSession?.tables ?? [], side: .right)
            }
            Divider().opacity(0.2)
            if migrationVisible {
                migrationPreview
            }
        }
        .background(.ultraThinMaterial)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.split.2x1.fill")
                .foregroundStyle(AppTheme.accent)
            Text("Schema Diff")
                .font(AppTypography.headline(14))
            Spacer()
            Picker("Target", selection: Binding<UUID?>(
                get: { rightSessionID },
                set: { rightSessionID = $0 }
            )) {
                Text("— pick connection —").tag(UUID?.none)
                ForEach(Array(connectionStore.sessions.values), id: \.id) { other in
                    if other.id != session.id, other.status.isConnected {
                        Text(other.config.name).tag(Optional(other.id))
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)

            Button {
                migrationVisible.toggle()
            } label: {
                Label(migrationVisible ? "Hide Migration" : "Generate Migration",
                      systemImage: "doc.text")
            }
            .buttonStyle(HoverableButtonStyle(tint: AppTheme.accent))
            .controlSize(.small)
            .disabled(rightSession == nil)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    private enum Side { case left, right }

    @ViewBuilder
    private func pane(title: String, tables: [TableInfo], side: Side) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: side == .left ? "arrow.left.circle" : "arrow.right.circle")
                    .foregroundStyle(AppTheme.accent)
                Text(title).font(AppTypography.headline(13))
                Spacer()
                Text("\(tables.count) tables")
                    .font(AppTypography.metadata(11))
                    .foregroundStyle(AppTheme.tertiaryLabel)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            Divider().opacity(0.2)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(deltas) { delta in
                        diffRow(delta: delta, side: side)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func diffRow(delta: SchemaDelta, side: Side) -> some View {
        let visibleOnSide: Bool = {
            switch (delta.kind, side) {
            case (.added, .left): return false
            case (.removed, .right): return false
            default: return true
            }
        }()
        HStack(spacing: 8) {
            Image(systemName: kindSymbol(delta.kind))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(kindColor(delta.kind))
                .frame(width: 12)
            Text(delta.table)
                .font(AppTypography.mono(12))
                .opacity(visibleOnSide ? 1 : 0.25)
            Spacer()
            if let rows = (side == .left ? delta.leftRows : delta.rightRows) {
                Text("~\(rows)")
                    .font(AppTypography.metadata(10))
                    .foregroundStyle(AppTheme.tertiaryLabel)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(kindColor(delta.kind).opacity(visibleOnSide ? 0.10 : 0.0))
    }

    private func kindSymbol(_ kind: SchemaDelta.Kind) -> String {
        switch kind {
        case .added:     return "plus.circle.fill"
        case .removed:   return "minus.circle.fill"
        case .modified:  return "exclamationmark.triangle.fill"
        case .unchanged: return "equal.circle"
        }
    }

    private func kindColor(_ kind: SchemaDelta.Kind) -> Color {
        switch kind {
        case .added:     return AppTheme.success
        case .removed:   return AppTheme.danger
        case .modified:  return AppTheme.warning
        case .unchanged: return AppTheme.tertiaryLabel
        }
    }

    private var migrationPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Migration Preview", systemImage: "doc.text")
                    .font(AppTypography.headline(13))
                Spacer()
                Button("Save…") {
                    ExportService.savePanel(suggested: "migration.sql", content: SchemaDiff.migrationScript(deltas: deltas))
                }
                .buttonStyle(HoverableButtonStyle(tint: .secondary))
                .controlSize(.small)
            }
            ScrollView {
                Text(SchemaDiff.migrationScript(deltas: deltas))
                    .font(AppTypography.mono(11))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 180)
        }
        .padding(12)
        .background(.regularMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
