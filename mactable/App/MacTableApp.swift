//
//  MacTableApp.swift
//  mactable
//

import SwiftUI
import SwiftData

@main
struct MacTableApp: App {
    @StateObject private var toastCenter = ToastCenter()
    @StateObject private var connectionStore = ConnectionStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedConnection.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer failure: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(toastCenter)
                .environmentObject(connectionStore)
                .frame(minWidth: 1100, minHeight: 700)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Query Tab") {
                    NotificationCenter.default.post(name: .newQueryTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            CommandMenu("Query") {
                Button("Execute") {
                    NotificationCenter.default.post(name: .executeQuery, object: nil)
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
    }
}
