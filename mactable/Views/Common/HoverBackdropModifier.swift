//
//  HoverBackdropModifier.swift
//  mactable
//
//  Applies a rounded-rectangle hover backdrop that mirrors macOS native
//  sidebar list semantics. Selection state takes precedence over hover.
//

import SwiftUI

struct HoverBackdropModifier: ViewModifier {
    let isSelected: Bool
    var cornerRadius: CGFloat = 6
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backdropColor)
                    .animation(.spring(response: 0.35, dampingFraction: 0.73), value: isHovered)
                    .animation(.spring(response: 0.35, dampingFraction: 0.73), value: isSelected)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onHover { isHovered = $0 }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var backdropColor: Color {
        if isSelected { return AppTheme.rowSelectedBackdrop }
        if isHovered  { return AppTheme.rowHoverBackdrop }
        return .clear
    }
}

extension View {
    func hoverBackdrop(isSelected: Bool = false, cornerRadius: CGFloat = 6) -> some View {
        modifier(HoverBackdropModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}
