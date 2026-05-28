//
//  RootView.swift
//  mactable
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var connectionStore: ConnectionStore
    @EnvironmentObject private var toastCenter: ToastCenter
    @Query private var savedConnections: [SavedConnection]
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedConnectionID: UUID?
    @State private var showConnectionForm = false
    @State private var editingConnection: SavedConnection?

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(
                savedConnections: savedConnections,
                selectedConnectionID: $selectedConnectionID,
                onAdd: { editingConnection = nil; showConnectionForm = true },
                onEdit: { conn in editingConnection = conn; showConnectionForm = true }
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            WorkspaceView(connectionID: selectedConnectionID)
        }
        .sheet(isPresented: $showConnectionForm) {
            ConnectionFormView(existing: editingConnection)
                .frame(minWidth: 520, minHeight: 600)
        }
        .overlay(alignment: .bottomTrailing) {
            ToastOverlayView()
                .environmentObject(toastCenter)
                .padding(20)
        }
        .background(.ultraThinMaterial)
    }
}
