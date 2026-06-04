//
//  AppNotifications+Palette.swift
//  mactable
//
//  Notification names used by the Cmd+K command palette to broadcast
//  invocation events without coupling the controller to specific views.
//

import Foundation

extension Notification.Name {
    static let paletteAction = Notification.Name("mactable.paletteAction")
    static let togglePalette = Notification.Name("mactable.togglePalette")
    static let switchWorkspaceTab = Notification.Name("mactable.switchWorkspaceTab")
    static let openTableInWorkspace = Notification.Name("mactable.openTableInWorkspace")
    static let toggleSafeMode = Notification.Name("mactable.toggleSafeMode")
    static let formatSQL = Notification.Name("mactable.formatSQL")
    static let runSavedQuery = Notification.Name("mactable.runSavedQuery")
}
