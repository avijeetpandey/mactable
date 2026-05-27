//
//  WorkspaceTabBar.swift
//  mactable
//

import SwiftUI

struct WorkspaceTabBar: View {
    @Binding var selectedTab: String
    @ObservedObject var session: ConnectionSession

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: session.config.kind.symbolName)
                    .foregroundStyle(session.config.kind.accentColor)
                Text(session.config.name)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Text(session.driver.serverVersion ?? "")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            tabButton(.editor, label: "Editor", icon: "terminal.fill")
            tabButton(.dashboard, label: "Dashboard", icon: "chart.line.uptrend.xyaxis")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private func tabButton(_ tab: WorkspaceTab, label: String, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab.rawValue
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(.callout, design: .rounded, weight: .medium))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selectedTab == tab.rawValue ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .foregroundStyle(selectedTab == tab.rawValue ? Color.accentColor : Color.primary)
    }
}
