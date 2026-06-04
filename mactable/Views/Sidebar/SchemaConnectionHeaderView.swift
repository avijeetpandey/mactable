//
//  SchemaConnectionHeaderView.swift
//  mactable
//
//  The top-level navigator row for a saved connection. Composes:
//    • Animated chevron driven by expansion state
//    • Database-kind SF Symbol coloured by accent
//    • Connection name (rounded heavy) + host:port subtitle
//    • Live StatusDotView reflecting ConnectionSession state
//    • Hover backdrop / selection backdrop
//    • Context menu (connect / disconnect / edit / delete)
//

import SwiftUI

struct SchemaConnectionHeaderView: View {
    let saved: SavedConnection
    let session: ConnectionSession?
    let isExpanded: Bool
    let isSelected: Bool
    let onTapHeader: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        Button(action: onTapHeader) {
            HStack(spacing: 8) {
                AnimatedChevronView(isExpanded: isExpanded)

                Image(systemName: saved.kind.symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(saved.kind.accentColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(saved.name)
                        .font(AppTypography.headline(13))
                        .foregroundStyle(AppTheme.primaryLabel)
                        .lineLimit(1)
                    Text("\(saved.kind.displayName) · \(saved.host):\(saved.port)")
                        .font(AppTypography.metadata(11))
                        .foregroundStyle(AppTheme.secondaryLabel)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                StatusDotView(status: session?.status ?? .idle)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverBackdrop(isSelected: isSelected, cornerRadius: 8)
        .padding(.horizontal, 6)
        .contextMenu {
            if session?.status.isConnected == true {
                Button("Disconnect", action: onDisconnect)
            } else {
                Button("Connect", action: onConnect)
            }
            Button("Edit Connection…", action: onEdit)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
