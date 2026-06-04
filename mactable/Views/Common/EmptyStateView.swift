//
//  EmptyStateView.swift
//  mactable
//
//  Premium empty state with asymmetric spring fade entry — the symbol
//  scales in first, then the headline and message stagger in behind it.
//

import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @State private var animateIn = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppTheme.tertiaryLabel)
                .scaleEffect(animateIn ? 1.0 : 0.6)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.spring(response: 0.45, dampingFraction: 0.68).delay(0.05), value: animateIn)
            Text(title)
                .font(AppTypography.headline(17))
                .foregroundStyle(AppTheme.secondaryLabel)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 6)
                .animation(.spring(response: 0.40, dampingFraction: 0.78).delay(0.15), value: animateIn)
            Text(message)
                .font(AppTypography.body(13))
                .foregroundStyle(AppTheme.tertiaryLabel)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 6)
                .animation(.spring(response: 0.40, dampingFraction: 0.78).delay(0.22), value: animateIn)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(HoverableButtonStyle())
                    .padding(.top, 6)
                    .opacity(animateIn ? 1 : 0)
                    .scaleEffect(animateIn ? 1 : 0.94)
                    .animation(.spring(response: 0.40, dampingFraction: 0.78).delay(0.30), value: animateIn)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear { animateIn = true }
    }
}

