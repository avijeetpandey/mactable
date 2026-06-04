//
//  ERDNodeView.swift
//  mactable
//
//  Single ERD node card.
//

import SwiftUI

struct ERDNodeView: View {
    let node: ERDNode
    let isDragging: Bool
    let onPortRelease: (ERDColumn, CGPoint) -> Void
    let onPortDrag: (CGPoint) -> Void
    let onBodyDrag: (CGSize) -> Void
    let onBodyDragEnded: (CGSize) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.2)
            VStack(spacing: 0) {
                ForEach(node.columns, id: \.name) { col in
                    columnRow(col)
                }
            }
        }
        .frame(width: node.size.width, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDragging ? AppTheme.accent : AppTheme.hairline, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: isDragging ? 18 : 8, y: 4)
        .gesture(
            DragGesture()
                .onChanged { onBodyDrag($0.translation) }
                .onEnded   { onBodyDragEnded($0.translation) }
        )
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "tablecells")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            Text(node.table)
                .font(AppTypography.headline(13))
            Spacer()
            Text(node.schema)
                .font(AppTypography.metadata(10))
                .foregroundStyle(AppTheme.tertiaryLabel)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func columnRow(_ col: ERDColumn) -> some View {
        HStack(spacing: 6) {
            Image(systemName: col.isPrimary ? "key.fill" : (col.foreignReference != nil ? "link" : "circle"))
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(col.isPrimary ? AppTheme.warning : (col.foreignReference != nil ? AppTheme.accent : AppTheme.tertiaryLabel))
                .frame(width: 12)
            Text(col.name)
                .font(AppTypography.mono(11))
            Spacer(minLength: 4)
            Text(col.typeName)
                .font(AppTypography.metadata(9))
                .foregroundStyle(AppTheme.tertiaryLabel)
            ZStack {
                Circle().stroke(AppTheme.accent, lineWidth: 1).frame(width: 10, height: 10)
                Circle().fill(AppTheme.accentSoft).frame(width: 6, height: 6)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ERDPortAnchorKey.self,
                        value: [ERDPortAnchor(table: node.table, column: col.name, frame: proxy.frame(in: .named("erd-canvas")))]
                    )
                }
            )
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named("erd-canvas"))
                    .onChanged { onPortDrag($0.location) }
                    .onEnded   { onPortRelease(col, $0.location) }
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

struct ERDPortAnchor: Hashable { let table: String; let column: String; let frame: CGRect }

struct ERDPortAnchorKey: PreferenceKey {
    static var defaultValue: [ERDPortAnchor] = []
    static func reduce(value: inout [ERDPortAnchor], nextValue: () -> [ERDPortAnchor]) {
        value.append(contentsOf: nextValue())
    }
}
