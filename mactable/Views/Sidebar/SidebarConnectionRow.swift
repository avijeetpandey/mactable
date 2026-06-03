//
//  SidebarConnectionRow.swift
//  mactable
//

import SwiftUI

struct SidebarConnectionRow: View {
    let saved: SavedConnection
    let session: ConnectionSession?
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: saved.kind.symbolName)
                    .foregroundStyle(saved.kind.accentColor)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(saved.name)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text("\(saved.kind.displayName) · \(saved.host):\(saved.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusDotView(status: session?.status ?? .idle)
            }
            if let session = session, session.status.isConnected, !session.tables.isEmpty {
                tableList(session: session)
            }
        }
        .padding(.vertical, 4)
        .onHover { isHovered = $0 }
        .contextMenu {
            if session?.status.isConnected == true {
                Button("Disconnect", action: onDisconnect)
            } else {
                Button("Connect", action: onConnect)
            }
            Button("Edit…", action: onEdit)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onTapGesture(count: 2) {
            if session?.status.isConnected != true { onConnect() }
        }
    }

    @ViewBuilder
    private func tableList(session: ConnectionSession) -> some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(session.tables) { table in
                HStack(spacing: 8) {
                    Image(systemName: table.kind.symbolName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(table.displayName)
                        .font(.system(.callout, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.vertical, 2)
            }
        } label: {
            Text("\(session.tables.count) tables")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 28)
    }
}
