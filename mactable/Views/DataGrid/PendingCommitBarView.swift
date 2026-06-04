//
//  PendingCommitBarView.swift
//  mactable
//
//  Pulsing commit bar surfaced at the bottom of the data grid whenever
//  the `MutationsQueue` has uncommitted edits. The bar shows count, lists
//  individual mutations on hover, and exposes Commit / Discard actions.
//

import SwiftUI

struct PendingCommitBarView: View {
    @ObservedObject var queue: MutationsQueue
    let onCommit: () -> Void
    let onDiscard: () -> Void
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.25))
                    .frame(width: 24, height: 24)
                    .scaleEffect(pulse ? 1.6 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.warning)
                    .font(.system(size: 14, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(queue.count) pending mutation\(queue.count == 1 ? "" : "s")")
                    .font(AppTypography.headline(13))
                Text("Safe Mode is buffering edits — commit to write to the database.")
                    .font(AppTypography.metadata(11))
                    .foregroundStyle(AppTheme.secondaryLabel)
            }
            Spacer()
            Button(role: .cancel, action: onDiscard) {
                Label("Discard", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(HoverableButtonStyle(tint: .secondary))
            .controlSize(.small)
            Button(action: onCommit) {
                Label("Commit Changes", systemImage: "checkmark.seal.fill")
                    .font(AppTypography.control(13))
            }
            .buttonStyle(HoverableButtonStyle(tint: AppTheme.accent))
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.warning.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .onAppear { pulse = true }
        .help(queue.compileSQL().joined(separator: "\n"))
    }
}
