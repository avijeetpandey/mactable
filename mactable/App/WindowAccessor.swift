//
//  WindowAccessor.swift
//  mactable
//

import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let window = v.window {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isMovableByWindowBackground = true
                window.toolbar?.showsBaselineSeparator = false
            }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
