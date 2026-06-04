//
//  GridHeaderCellView.swift
//  mactable
//
//  Sticky grid column header. Renders the column name in SF Mono, the
//  declared SQL type in metadata weight, an animated sort glyph that
//  flips between ascending/descending, and a 1pt trailing column rule.
//

import SwiftUI

struct GridHeaderCellView: View {
    let column: ColumnDescriptor
    let sortDirection: GridSortDescriptor.Direction?
    let width: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(column.name)
                    .font(AppTypography.mono(12, weight: .semibold))
                    .lineLimit(1)
                Text(column.typeName)
                    .font(AppTypography.metadata(10))
                    .foregroundStyle(AppTheme.tertiaryLabel)
                Spacer(minLength: 4)
                if let dir = sortDirection {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .rotationEffect(.degrees(dir == .ascending ? 0 : 180))
                        .animation(.spring(response: 0.35, dampingFraction: 0.73), value: dir)
                }
            }
            .padding(.horizontal, 10)
            .frame(width: width, height: 28, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .overlay(
            Rectangle().fill(AppTheme.hairline.opacity(0.5))
                .frame(width: 1).frame(maxHeight: .infinity),
            alignment: .trailing
        )
    }
}
