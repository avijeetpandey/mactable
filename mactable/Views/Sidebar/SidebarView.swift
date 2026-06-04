//
//  SidebarView.swift
//  mactable
//
//  Premium hierarchical navigator: connection header card + recursive
//  Connection → Schema → Table tree powered by SchemaTreeView.
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

    @State private var expandedNodeIDs: Set<String> = []
    @State private var selectedNodeID: String?

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            InnerShadowDividerView()
            if savedConnections.isEmpty {
                EmptyStateView(
                    symbol: "tray.fill",
                    title: "No Connections",
                    message: "Add your first PostgreSQL, MySQL, or MongoDB connection to get started.",
                    actionTitle: "Add Connection",
                    action: onAdd
                )
            } else {
                connectionList
            }
            InnerShadowDividerView()
            sidebarFooter
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Header / Footer

    private var sidebarHeader: some View {
        HStack {
            Image(systemName: "cylinder.split.1x2.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text("MacTable")
                .font(AppTypography.headline(17))
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
            .help("Add Connection")
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    private var sidebarFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(AppTheme.tertiaryLabel)
            Text("\(savedConnections.count) connection\(savedConnections.count == 1 ? "" : "s")")
                .font(AppTypography.metadata(11))
                .foregroundStyle(AppTheme.secondaryLabel)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Connection list

    private var connectionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(savedConnections, id: \.id) { saved in
                    connectionSection(for: saved)
                }
            }
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func connectionSection(for saved: SavedConnection) -> some View {
        let session = connectionStore.session(for: saved.id)
        let rootID = "\(saved.id.uuidString):root"

        SchemaConnectionHeaderView(
            saved: saved,
            session: session,
            isExpanded: expandedNodeIDs.contains(rootID),
            isSelected: selectedConnectionID == saved.id,
            onTapHeader: {
                selectedConnectionID = saved.id
                if session?.status.isConnected == true {
                    toggleNode(rootID, session: session)
                } else {
                    connect(saved)
                }
            },
            onEdit: { onEdit(saved) },
            onDelete: { delete(saved) },
            onConnect: { connect(saved) },
            onDisconnect: { connectionStore.disconnect(id: saved.id) }
        )

        if expandedNodeIDs.contains(rootID), let session = session, session.status.isConnected {
            let root = SchemaTreeBuilder.build(for: session)
            SchemaTreeView(
                roots: root.children,
                selectedNodeID: $selectedNodeID,
                expandedNodeIDs: $expandedNodeIDs,
                onSelectTable: { _ in selectedConnectionID = saved.id },
                onExpand: { node in hydrate(node, in: session) }
            )
            .frame(maxHeight: dynamicTreeHeight(for: session))
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity
            ))
        }
    }

    private func dynamicTreeHeight(for session: ConnectionSession) -> CGFloat {
        // Soft cap: 22 px/row × visible rows + buffer; clamp to ≤ 480 so the
        // tree never crowds the footer on small windows.
        let approxRows = max(session.tables.count, 1) + 8
        return min(CGFloat(approxRows) * 22, 480)
    }

    // MARK: - Actions

    private func toggleNode(_ id: String, session: ConnectionSession?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.73)) {
            if expandedNodeIDs.contains(id) {
                expandedNodeIDs.remove(id)
            } else {
                expandedNodeIDs.insert(id)
                if let session = session, session.tables.isEmpty {
                    Task { await session.refreshTables() }
                }
            }
        }
    }

    private func hydrate(_ node: SchemaNode, in session: ConnectionSession) {
        // Schema-level nodes are derived from the bulk fetchTables() call so
        // they're already populated, but we still kick off a refresh on first
        // expand so newly-added objects appear without a manual reconnect.
        if case .schema = node.kind {
            Task { await session.refreshTables() }
        }
    }

    private func connect(_ saved: SavedConnection) {
        connectionStore.startConnecting(config: saved.config)
        saved.lastUsedAt = Date()
        try? modelContext.save()
        toastCenter.push("Connecting to \(saved.name)…", kind: .info)
        // Auto-expand the connection root once connected.
        let rootID = "\(saved.id.uuidString):root"
        expandedNodeIDs.insert(rootID)
    }

    private func delete(_ saved: SavedConnection) {
        KeychainService.deletePassword(for: saved.id)
        connectionStore.disconnect(id: saved.id)
        modelContext.delete(saved)
        try? modelContext.save()
        toastCenter.push("Removed \(saved.name)", kind: .warning)
    }
}

