//
//  CRDTDelta.swift
//  mactable
//
//  Operation-Based Sequence CRDT applied to the SQL editor buffer. We use
//  a simplified RGA-style approach: every insertion carries a unique
//  `(siteID, lamport)` identifier and the previous character's id, which
//  allows concurrent edits to converge deterministically without the cost
//  of a full vector clock implementation.
//

import Foundation

struct CRDTDelta: Hashable {
    enum Op: Hashable {
        case insert(character: String, after: CRDTID?)
        case delete(id: CRDTID)
    }
    let op: Op
    let id: CRDTID
}

struct CRDTID: Hashable, Comparable {
    let siteID: UUID
    let lamport: UInt64

    static func < (lhs: CRDTID, rhs: CRDTID) -> Bool {
        if lhs.lamport != rhs.lamport { return lhs.lamport < rhs.lamport }
        return lhs.siteID.uuidString < rhs.siteID.uuidString
    }
}

/// In-memory CRDT document that exposes a plain string view via `text`.
/// Concurrent inserts converge regardless of arrival order.
final class CRDTDocument {
    private struct Node { let id: CRDTID; var character: String; var tombstoned: Bool; var afterID: CRDTID? }
    private var nodes: [Node] = []
    private(set) var lamport: UInt64 = 0
    let siteID: UUID

    init(siteID: UUID = UUID()) {
        self.siteID = siteID
    }

    var text: String {
        nodes.filter { !$0.tombstoned }.map(\.character).joined()
    }

    @discardableResult
    func localInsert(character: String, atIndex index: Int) -> CRDTDelta {
        lamport += 1
        let after = nodeID(visibleIndex: index - 1)
        let id = CRDTID(siteID: siteID, lamport: lamport)
        let delta = CRDTDelta(op: .insert(character: character, after: after), id: id)
        applyRemote(delta)
        return delta
    }

    @discardableResult
    func localDelete(atIndex index: Int) -> CRDTDelta? {
        guard let id = nodeID(visibleIndex: index) else { return nil }
        let delta = CRDTDelta(op: .delete(id: id), id: id)
        applyRemote(delta)
        return delta
    }

    func applyRemote(_ delta: CRDTDelta) {
        switch delta.op {
        case .insert(let character, let after):
            // Insert just after the referenced node, observing tie-break by id
            // descending (later concurrent inserts sit closer to the anchor).
            let insertionIndex: Int
            if let after = after, let anchor = nodes.firstIndex(where: { $0.id == after }) {
                var idx = anchor + 1
                while idx < nodes.count, nodes[idx].afterID == after, nodes[idx].id > delta.id {
                    idx += 1
                }
                insertionIndex = idx
            } else {
                var idx = 0
                while idx < nodes.count, nodes[idx].afterID == nil, nodes[idx].id > delta.id {
                    idx += 1
                }
                insertionIndex = idx
            }
            nodes.insert(Node(id: delta.id, character: character, tombstoned: false, afterID: after), at: insertionIndex)
            if delta.id.lamport > lamport { lamport = delta.id.lamport }
        case .delete(let id):
            if let idx = nodes.firstIndex(where: { $0.id == id }) {
                nodes[idx].tombstoned = true
            }
        }
    }

    private func nodeID(visibleIndex: Int) -> CRDTID? {
        guard visibleIndex >= 0 else { return nil }
        var seen = -1
        for n in nodes where !n.tombstoned {
            seen += 1
            if seen == visibleIndex { return n.id }
        }
        return nil
    }
}
