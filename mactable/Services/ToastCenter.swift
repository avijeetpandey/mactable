//
//  ToastCenter.swift
//  mactable
//

import SwiftUI
import Combine

@MainActor
final class ToastCenter: ObservableObject {
    @Published private(set) var toasts: [ToastMessage] = []
    private var counter: UInt64 = 0

    func push(_ message: String, kind: ToastKind = .info, duration: TimeInterval = 3.5) {
        counter &+= 1
        let toast = ToastMessage(id: counter, message: message, kind: kind)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            toasts.append(toast)
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.dismiss(toast.id)
        }
    }

    func dismiss(_ id: UInt64) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            toasts.removeAll { $0.id == id }
        }
    }

    func error(_ error: Error) {
        push(error.localizedDescription, kind: .error, duration: 5.0)
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id: UInt64
    let message: String
    let kind: ToastKind
}

enum ToastKind {
    case info, success, warning, error

    var symbolName: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:    return .accentColor
        case .success: return .green
        case .warning: return .orange
        case .error:   return .red
        }
    }
}
