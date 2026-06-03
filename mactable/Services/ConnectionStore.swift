//
//  ConnectionStore.swift
//  mactable
//
//  Owns active driver instances keyed by connection ID.
//

import Foundation
import Combine

@MainActor
final class ConnectionStore: ObservableObject {
    @Published private(set) var sessions: [UUID: ConnectionSession] = [:]

    func session(for id: UUID) -> ConnectionSession? { sessions[id] }

    func startConnecting(config: ConnectionConfig) {
        let session = ConnectionSession(config: config)
        sessions[config.id] = session
        Task { await session.connect() }
    }

    func disconnect(id: UUID) {
        guard let session = sessions[id] else { return }
        Task {
            await session.disconnect()
            await MainActor.run { self.sessions.removeValue(forKey: id) }
        }
    }
}

@MainActor
final class ConnectionSession: ObservableObject, Identifiable {
    let id: UUID
    let config: ConnectionConfig
    let driver: DatabaseDriver

    @Published var status: ConnectionStatus = .idle
    @Published var tables: [TableInfo] = []
    @Published var lastError: String?

    init(config: ConnectionConfig) {
        self.id = config.id
        self.config = config
        self.driver = DriverFactory.make(for: config.kind)
    }

    func connect() async {
        status = .connecting
        let password = KeychainService.loadPassword(for: config.id) ?? ""
        do {
            try await driver.connect(config: config, password: password)
            let tables = (try? await driver.fetchTables()) ?? []
            await MainActor.run {
                self.tables = tables
                self.status = .connected
            }
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.status = .failed(error.localizedDescription)
            }
        }
    }

    func disconnect() async {
        await driver.disconnect()
        await MainActor.run { self.status = .idle }
    }

    func refreshTables() async {
        do {
            let tables = try await driver.fetchTables()
            await MainActor.run { self.tables = tables }
        } catch {
            await MainActor.run { self.lastError = error.localizedDescription }
        }
    }
}

enum ConnectionStatus: Equatable {
    case idle
    case connecting
    case connected
    case failed(String)

    var isConnected: Bool { if case .connected = self { return true } else { return false } }
    var isConnecting: Bool { if case .connecting = self { return true } else { return false } }
}
