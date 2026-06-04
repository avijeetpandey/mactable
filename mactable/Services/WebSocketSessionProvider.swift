//
//  WebSocketSessionProvider.swift
//  mactable
//
//  Protocol abstraction over the multiplayer transport. Phase 7 ships with
//  an in-process loopback implementation so the entire collaboration
//  pipeline (cursors, CRDT merges, presence) is exercised in tests and
//  during local development without requiring a remote server.
//

import Foundation
import Combine

protocol WebSocketSessionProvider: AnyObject {
    var publisher: AnyPublisher<CollaborationEvent, Never> { get }
    func connect()
    func disconnect()
    func send(_ event: CollaborationEvent)
}

enum CollaborationEvent {
    case cursor(PeerCursor)
    case delta(CRDTDelta)
    case peerLeft(UUID)
}

struct PeerCursor: Identifiable, Hashable {
    let id: UUID
    let displayInitials: String
    let colorHex: String
    var line: Int
    var column: Int

    static func local(line: Int, column: Int) -> PeerCursor {
        PeerCursor(id: PeerIdentity.localID,
                   displayInitials: PeerIdentity.localInitials,
                   colorHex: PeerIdentity.localColorHex,
                   line: line,
                   column: column)
    }
}

enum PeerIdentity {
    static let localID = UUID()
    static let localInitials = "ME"
    static let localColorHex = "#5947F7"
}
