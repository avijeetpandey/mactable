//
//  SQLEditorPillBarView.swift
//  mactable
//
//  Floating glass pill bar that hovers above the editor viewport. Hosts
//  Run, Format, and Safe-Mode toggle as iconified controls. Fades out
//  when the editor is being scrolled (so it doesn't obstruct text) and
//  springs back into view on scroll-stop.
//

import SwiftUI

struct SQLEditorPillBarView: View {
    @ObservedObject var viewModel: QueryEditorViewModel
    @State private var hovering: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            pillButton(
                title: viewModel.isExecuting ? "Running…" : "Run",
                symbol: viewModel.isExecuting ? "stop.fill" : "play.fill",
                tint: AppTheme.success,
                shortcut: "⌘⏎",
                isActive: !viewModel.isExecuting
            ) { viewModel.run() }
                .disabled(viewModel.isExecuting)

            divider

            pillButton(
                title: "Format",
                symbol: "wand.and.stars",
                tint: AppTheme.accent,
                shortcut: "⇧⌘F",
                isActive: true
            ) { viewModel.formatSQL() }

            divider

            pillButton(
                title: viewModel.safeMode ? "Production Locked" : "Production Open",
                symbol: viewModel.safeMode ? "lock.shield.fill" : "lock.open.fill",
                tint: viewModel.safeMode ? AppTheme.warning : AppTheme.danger,
                shortcut: nil,
                isActive: true
            ) { viewModel.toggleSafeMode() }

            if viewModel.result.executionTime > 0 {
                divider
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(Int(viewModel.result.executionTime * 1000)) ms")
                        .font(AppTypography.mono(11))
                        .monospacedDigit()
                    Text("·").foregroundStyle(AppTheme.tertiaryLabel)
                    Text("\(viewModel.result.rows.count) rows")
                        .font(AppTypography.mono(11))
                        .monospacedDigit()
                }
                .foregroundStyle(AppTheme.secondaryLabel)
                .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule().stroke(AppTheme.hairline, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .scaleEffect(hovering ? 1.015 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.73), value: hovering)
        .onHover { hovering = $0 }
        .keyboardShortcut("f", modifiers: [.command, .shift])
    }

    @ViewBuilder
    private func pillButton(title: String, symbol: String, tint: Color, shortcut: String?, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isActive ? tint : AppTheme.tertiaryLabel)
                Text(title)
                    .font(AppTypography.control(12))
                if let s = shortcut {
                    Text(s)
                        .font(AppTypography.metadata(10))
                        .foregroundStyle(AppTheme.tertiaryLabel)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(AppTheme.rowHoverBackdrop))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background(
            Capsule().fill(Color.clear)
        )
        .onHover { hover in
            if hover {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.73)) {}
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.hairline.opacity(0.5))
            .frame(width: 1, height: 16)
    }
}
