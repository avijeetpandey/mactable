//
//  CollaborationCenter.swift
//  mactable
//
//  Phase-7 cooperative editing surface. Owns a `WebSocketSessionProvider`
//  (default: in-process loopback so the surface is fully wired without an
//  external server), tracks remote cursors, and applies CRDT deltas to
//  the shared SQL buffer.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CollaborationCenter: ObservableObject {
    @Published private(set) var peers: [PeerCursor] = []
    @Published var isLive: Bool = false

    private var provider: WebSocketSessionProvider
    private var cancellables: Set<AnyCancellable> = []

    init(provider: WebSocketSessionProvider = LoopbackCollaborationProvider()) {
        self.provider = provider
        provider.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in self?.apply(event) }
            .store(in: &cancellables)
    }

    func start() { isLive = true; provider.connect() }
    func stop()  { isLive = false; provider.disconnect(); peers = [] }

    func broadcast(delta: CRDTDelta) {
        guard isLive else { return }
        provider.send(.delta(delta))
    }

    func updateLocalCursor(line: Int, column: Int) {
        guard isLive else { return }
        provider.send(.cursor(PeerCursor.local(line: line, column: column)))
    }

    private func apply(_ event: CollaborationEvent) {
        switch event {
        case .cursor(let cursor):
            if let idx = peers.firstIndex(where: { $0.id == cursor.id }) {
                peers[idx] = cursor
            } else {
                peers.append(cursor)
            }
        case .delta:
            // Deltas are routed by interested editors via `provider.publisher`
            // directly; the center merely tallies activity.
            break
        case .peerLeft(let id):
            peers.removeAll { $0.id == id }
        }
    }
}
