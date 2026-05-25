//
//  StatusDotView.swift
//  mactable
//

import SwiftUI

struct StatusDotView: View {
    let status: ConnectionStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(Circle().stroke(color.opacity(0.4), lineWidth: 1.5).blur(radius: 2))
            .animation(.easeInOut(duration: 0.4), value: status)
    }

    private var color: Color {
        switch status {
        case .connected:  return .green
        case .connecting: return .orange
        case .failed:     return .red
        case .idle:       return .gray
        }
    }
}
