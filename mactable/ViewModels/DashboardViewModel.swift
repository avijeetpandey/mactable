//
//  DashboardViewModel.swift
//  mactable
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var metrics: DatabaseMetrics = .empty
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let session: ConnectionSession
    private var refreshTask: Task<Void, Never>?

    init(session: ConnectionSession) {
        self.session = session
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let m = try await session.driver.fetchMetrics()
            self.metrics = m
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
