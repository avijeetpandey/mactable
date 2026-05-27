//
//  HoverableButtonStyle.swift
//  mactable
//

import SwiftUI

struct HoverableButtonStyle: ButtonStyle {
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        HoverableButtonContent(configuration: configuration, tint: tint)
    }
}

private struct HoverableButtonContent: View {
    let configuration: ButtonStyle.Configuration
    let tint: Color
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? tint.opacity(0.18) : tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(tint.opacity(isHovered ? 0.55 : 0.25), lineWidth: 1)
            )
            .foregroundStyle(tint)
            .scaleEffect(configuration.isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}
