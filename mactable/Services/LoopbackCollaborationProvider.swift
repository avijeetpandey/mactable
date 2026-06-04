//
//  LoopbackCollaborationProvider.swift
//  mactable
//
//  Default `WebSocketSessionProvider` that runs entirely in-process. Useful
//  for verifying the multiplayer pipeline end-to-end before any external
//  signalling server is plugged in. Echoes every send back through the
//  publisher so the rest of the stack treats it identically to a remote
//  socket peer.
//

import Foundation
import Combine

final class LoopbackCollaborationProvider: WebSocketSessionProvider {
    private let subject = PassthroughSubject<CollaborationEvent, Never>()
    private(set) var connected: Bool = false

    var publisher: AnyPublisher<CollaborationEvent, Never> { subject.eraseToAnyPublisher() }

    func connect() { connected = true }

    func disconnect() {
        connected = false
        subject.send(.peerLeft(PeerIdentity.localID))
    }

    func send(_ event: CollaborationEvent) {
        guard connected else { return }
        // Loopback: echo back so the same client sees the event arrive
        // through the subscription pipeline (helpful for testing the
        // CollaborationCenter wiring without a remote peer).
        subject.send(event)
    }
}
