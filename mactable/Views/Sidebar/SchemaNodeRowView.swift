//
//  SchemaNodeRowView.swift
//  mactable
//
//  Renders one row of the navigator tree. Layout is consistent across
//  every level: chevron (or spacer for leaves) → SF Symbol → title +
//  optional subtitle. Hover backdrop is applied at the row level so
//  the entire interactive region lights up — not just the label.
//

import SwiftUI

struct SchemaNodeRowView: View {
    let node: SchemaNode
    let depth: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 6) {
                // Indentation grows with depth so nested levels visually nest.
                Spacer().frame(width: CGFloat(depth) * 12)

                if hasChildren {
                    AnimatedChevronView(isExpanded: isExpanded)
                } else {
                    Spacer().frame(width: 12, height: 12)
                }

                Image(systemName: node.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(symbolColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(node.title)
                        .font(titleFont)
                        .foregroundStyle(AppTheme.primaryLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let subtitle = node.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppTypography.metadata())
                            .foregroundStyle(AppTheme.tertiaryLabel)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverBackdrop(isSelected: isSelected, cornerRadius: 6)
        .padding(.horizontal, 6)
    }

    private var hasChildren: Bool {
        switch node.kind {
        case .connection, .schema: return true
        case .table:               return false
        }
    }

    private var titleFont: Font {
        switch node.kind {
        case .connection: return AppTypography.headline(13)
        case .schema:     return AppTypography.body(12.5)
        case .table:      return AppTypography.mono(12, weight: .medium)
        }
    }

    private var symbolColor: Color {
        switch node.kind {
        case .connection: return AppTheme.accent
        case .schema:     return AppTheme.secondaryLabel
        case .table(.view), .table(.materializedView):
            return AppTheme.accentVivid
        case .table:      return AppTheme.secondaryLabel
        }
    }

    private func handleTap() {
        if hasChildren {
            onToggle()
        } else {
            onSelect()
        }
    }
}
