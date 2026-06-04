//
//  CommandPaletteController.swift
//  mactable
//
//  Singleton @MainActor coordinator: opens / closes the palette, owns the
//  most recent index snapshot, and dispatches palette actions back to the
//  rest of the app via the shared NotificationCenter event bus.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CommandPaletteController: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var query: String = ""
    @Published var index: CommandPaletteIndex = CommandPaletteIndex(items: [])

    func toggle() {
        isPresented.toggle()
        if !isPresented { query = "" }
    }

    func dismiss() {
        isPresented = false
        query = ""
    }

    func updateIndex(savedConnections: [SavedConnection],
                     sessions: [UUID: ConnectionSession],
                     savedQueries: [SavedQuery]) {
        index = CommandPaletteIndexBuilder.build(
            savedConnections: savedConnections,
            sessions: sessions,
            savedQueries: savedQueries
        )
    }

    func invoke(_ item: CommandPaletteItem) {
        defer { dismiss() }
        NotificationCenter.default.post(name: .paletteAction, object: item.action)
    }
}
