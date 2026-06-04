//
//  PresenceCursorOverlayView.swift
//  mactable
//
//  Renders floating remote-peer cursors over the SQL editor. Each peer is
//  represented by an indigo pill carrying their initials; the pill follows
//  the WebSocket-streamed `(line, column)` updates with a soft spring.
//

import SwiftUI

struct PresenceCursorOverlayView: View {
    @ObservedObject var center: CollaborationCenter
    let lineHeight: CGFloat = 18
    let charWidth: CGFloat = 7.5

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(center.peers.filter { $0.id != PeerIdentity.localID }) { peer in
                cursorPill(for: peer)
                    .position(
                        x: CGFloat(peer.column) * charWidth + 24,
                        y: CGFloat(peer.line) * lineHeight + 18
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.73), value: peer.line)
                    .animation(.spring(response: 0.35, dampingFraction: 0.73), value: peer.column)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func cursorPill(for peer: PeerCursor) -> some View {
        HStack(spacing: 4) {
            Circle().fill(AppTheme.accent).frame(width: 6, height: 6)
            Text(peer.displayInitials)
                .font(AppTypography.metadata(10).weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(
            Capsule().fill(AppTheme.accent)
        )
        .shadow(color: AppTheme.accent.opacity(0.3), radius: 6)
    }
}
