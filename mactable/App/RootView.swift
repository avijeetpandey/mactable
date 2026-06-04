//
//  RootView.swift
//  mactable
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var connectionStore: ConnectionStore
    @EnvironmentObject private var toastCenter: ToastCenter
    @EnvironmentObject private var paletteController: CommandPaletteController
    @Query private var savedConnections: [SavedConnection]
    @Query private var savedQueries: [SavedQuery]
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedConnectionID: UUID?
    @State private var showConnectionForm = false
    @State private var editingConnection: SavedConnection?
    @State private var inspectorVisible: Bool = false

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
                .safeAreaInset(edge: .top, spacing: 0) {
                    InnerShadowDividerView()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            inspectorVisible.toggle()
                        } label: {
                            Image(systemName: inspectorVisible ? "sidebar.right" : "note.text")
                        }
                        .help("Toggle Scratchpad")
                        .disabled(selectedConnectionID == nil)
                    }
                }
                .inspector(isPresented: $inspectorVisible) {
                    if let id = selectedConnectionID {
                        ScratchpadInspectorView(connectionID: id)
                            .inspectorColumnWidth(min: 240, ideal: 320, max: 480)
                    } else {
                        EmptyStateView(
                            symbol: "note.text",
                            title: "No Connection",
                            message: "Select a connection to enable per-profile notes."
                        )
                    }
                }
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: $showConnectionForm) {
            ConnectionFormView(existing: editingConnection)
                .frame(minWidth: 520, minHeight: 600)
        }
        .overlay(alignment: .bottomTrailing) {
            ToastOverlayView()
                .environmentObject(toastCenter)
                .padding(20)
        }
        .overlay {
            if paletteController.isPresented {
                paletteOverlay
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.73), value: paletteController.isPresented)
        .background(.ultraThinMaterial)
        .onAppear { refreshPaletteIndex() }
        .onChange(of: savedConnections.count) { _, _ in refreshPaletteIndex() }
        .onChange(of: savedQueries.count) { _, _ in refreshPaletteIndex() }
        .onChange(of: connectionStore.sessions.count) { _, _ in refreshPaletteIndex() }
        .onReceive(NotificationCenter.default.publisher(for: .togglePalette)) { _ in
            refreshPaletteIndex()
            paletteController.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .paletteAction)) { note in
            guard let action = note.object as? PaletteAction else { return }
            handle(action: action)
        }
    }

    private var paletteOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture { paletteController.dismiss() }
            VStack {
                Spacer().frame(height: 90)
                CommandPaletteView(controller: paletteController)
                Spacer()
            }
        }
    }

    private func refreshPaletteIndex() {
        paletteController.updateIndex(
            savedConnections: savedConnections,
            sessions: connectionStore.sessions,
            savedQueries: savedQueries
        )
    }

    private func handle(action: PaletteAction) {
        switch action {
        case .selectConnection(let id):
            selectedConnectionID = id
        case .openTable(let id, let tableID):
            selectedConnectionID = id
            NotificationCenter.default.post(
                name: .openTableInWorkspace,
                object: OpenTableRequest(connectionID: id, tableID: tableID)
            )
        case .runSavedQuery(_, let sql, let connectionID):
            selectedConnectionID = connectionID
            NotificationCenter.default.post(name: .runSavedQuery, object: sql)
        case .appAction(let key):
            handle(appAction: key)
        case .focusSchema(let id, _):
            selectedConnectionID = id
        }
    }

    private func handle(appAction key: AppActionKey) {
        switch key {
        case .newQueryTab:
            NotificationCenter.default.post(name: .newQueryTab, object: nil)
        case .toggleSafeMode:
            NotificationCenter.default.post(name: .toggleSafeMode, object: nil)
        case .showDashboard:
            NotificationCenter.default.post(name: .switchWorkspaceTab, object: WorkspaceTab.dashboard.rawValue)
        case .showEditor:
            NotificationCenter.default.post(name: .switchWorkspaceTab, object: WorkspaceTab.editor.rawValue)
        case .formatSQL:
            NotificationCenter.default.post(name: .formatSQL, object: nil)
        case .openConnectionForm:
            editingConnection = nil
            showConnectionForm = true
        }
    }
}

struct OpenTableRequest: Hashable {
    let connectionID: UUID
    let tableID: String
}
