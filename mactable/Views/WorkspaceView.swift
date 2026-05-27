//
//  WorkspaceView.swift
//  mactable
//

import SwiftUI

struct WorkspaceView: View {
    let connectionID: UUID?
    @EnvironmentObject private var connectionStore: ConnectionStore
    @SceneStorage("mactable.workspaceTab") private var selectedTab: String = WorkspaceTab.editor.rawValue

    var body: some View {
        Group {
            if let id = connectionID, let session = connectionStore.session(for: id) {
                if session.status.isConnected {
                    workspaceContent(session: session)
                } else {
                    statusView(session: session)
                }
            } else {
                EmptyStateView(
                    symbol: "rectangle.connected.to.line.below",
                    title: "No Connection Selected",
                    message: "Choose a connection from the sidebar, or add a new one to begin."
                )
            }
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func workspaceContent(session: ConnectionSession) -> some View {
        VStack(spacing: 0) {
            WorkspaceTabBar(selectedTab: $selectedTab, session: session)
            Divider().opacity(0.2)
            switch WorkspaceTab(rawValue: selectedTab) ?? .editor {
            case .editor:    SQLEditorContainerView(session: session)
            case .dashboard: DashboardView(session: session)
            }
        }
    }

    @ViewBuilder
    private func statusView(session: ConnectionSession) -> some View {
        VStack(spacing: 16) {
            switch session.status {
            case .idle:
                EmptyStateView(symbol: "bolt.slash", title: "Not Connected",
                               message: "Tap the connection in the sidebar to connect.")
            case .connecting:
                VStack(spacing: 12) {
                    ProgressView().controlSize(.large)
                    Text("Connecting to \(session.config.name)…")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .redacted(reason: .placeholder)
                }
            case .connected:
                ProgressView()
            case .failed(let msg):
                EmptyStateView(symbol: "xmark.octagon", title: "Connection Failed", message: msg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum WorkspaceTab: String { case editor, dashboard }
