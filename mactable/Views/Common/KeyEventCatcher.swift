//
//  KeyEventCatcher.swift
//  mactable
//
//  A zero-sized NSViewRepresentable used to capture arrow / return / escape
//  keystrokes inside SwiftUI views (e.g. the Cmd+K palette) without
//  competing with the focused TextField for first responder status.
//

import SwiftUI
import AppKit

struct KeyEventCatcher: NSViewRepresentable {
    var onArrowDown: () -> Void = {}
    var onArrowUp:   () -> Void = {}
    var onReturn:    () -> Void = {}
    var onEscape:    () -> Void = {}

    func makeNSView(context: Context) -> KeyEventCatcherView {
        let v = KeyEventCatcherView()
        v.onArrowDown = onArrowDown
        v.onArrowUp = onArrowUp
        v.onReturn = onReturn
        v.onEscape = onEscape
        return v
    }

    func updateNSView(_ nsView: KeyEventCatcherView, context: Context) {
        nsView.onArrowDown = onArrowDown
        nsView.onArrowUp = onArrowUp
        nsView.onReturn = onReturn
        nsView.onEscape = onEscape
    }
}

final class KeyEventCatcherView: NSView {
    var onArrowDown: () -> Void = {}
    var onArrowUp:   () -> Void = {}
    var onReturn:    () -> Void = {}
    var onEscape:    () -> Void = {}

    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil, monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self, let window = self.window, event.window === window else { return event }
                switch event.keyCode {
                case 125: self.onArrowDown(); return nil
                case 126: self.onArrowUp(); return nil
                case 36, 76: self.onReturn(); return nil
                case 53: self.onEscape(); return nil
                default: return event
                }
            }
        } else if window == nil, let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        if let monitor = monitor { NSEvent.removeMonitor(monitor) }
    }
}
