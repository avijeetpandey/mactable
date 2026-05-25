//
//  SidebarView.swift
//  mactable
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    let savedConnections: [SavedConnection]
    @Binding var selectedConnectionID: UUID?
    let onAdd: () -> Void
    let onEdit: (SavedConnection) -> Void

    @EnvironmentObject private var connectionStore: ConnectionStore
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider().opacity(0.3)
            if savedConnections.isEmpty {
                EmptyStateView(
                    symbol: "tray.fill",
                    title: "No Connections",
                    message: "Add your first PostgreSQL, MySQL, or MongoDB connection to get started.",
                    actionTitle: "Add Connection",
                    action: onAdd
                )
            } else {
                List(selection: $selectedConnectionID) {
                    ForEach(savedConnections, id: \.id) { saved in
                        SidebarConnectionRow(
                            saved: saved,
                            session: connectionStore.session(for: saved.id),
                            onConnect: { connect(saved) },
                            onDisconnect: { connectionStore.disconnect(id: saved.id) },
                            onEdit: { onEdit(saved) },
                            onDelete: { delete(saved) }
                        )
                        .tag(saved.id)
                    }
                }
                .listStyle(.sidebar)
            }
            Divider().opacity(0.3)
            sidebarFooter
        }
        .background(.ultraThinMaterial)
    }

    private var sidebarHeader: some View {
        HStack {
            Image(systemName: "cylinder.split.1x2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.tint)
            Text("MacTable")
                .font(.system(.title3, design: .rounded, weight: .bold))
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .help("Add Connection")
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var sidebarFooter: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(.tertiary)
            Text("\(savedConnections.count) connection\(savedConnections.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func connect(_ saved: SavedConnection) {
        connectionStore.startConnecting(config: saved.config)
        saved.lastUsedAt = Date()
        try? modelContext.save()
        toastCenter.push("Connecting to \(saved.name)…", kind: .info)
    }

    private func delete(_ saved: SavedConnection) {
        KeychainService.deletePassword(for: saved.id)
        connectionStore.disconnect(id: saved.id)
        modelContext.delete(saved)
        try? modelContext.save()
        toastCenter.push("Removed \(saved.name)", kind: .warning)
    }
}
