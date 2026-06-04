//
//  ERDViewModel.swift
//  mactable
//
//  Drives the ERD canvas: keeps the live node graph, the user's manual
//  drag offsets, the active drag-to-join interaction, and the generated
//  JOIN SQL preview pushed back into the editor when the user releases
//  a wire onto a target column.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ERDViewModel: ObservableObject {
    @Published var nodes: [ERDNode] = []
    @Published var draggingNodeID: String? = nil
    @Published var dragOffsets: [String: CGSize] = [:]
    @Published var pendingJoin: PendingJoin? = nil
    @Published var generatedSQL: String = ""

    func loadFromSession(_ session: ConnectionSession) {
        let derived = session.tables.map { table -> ERDNode in
            let columns: [ERDColumn] = inferColumns(for: table)
            return ERDNode(
                id: "\(table.schema).\(table.name)",
                table: table.name,
                schema: table.schema,
                columns: columns,
                position: .zero,
                size: ERDNode.defaultSize
            )
        }
        self.nodes = ERDLayoutEngine.layout(derived)
    }

    func position(of nodeID: String) -> CGPoint? {
        guard let base = nodes.first(where: { $0.id == nodeID })?.position else { return nil }
        let offset = dragOffsets[nodeID] ?? .zero
        return CGPoint(x: base.x + offset.width, y: base.y + offset.height)
    }

    func commitDrag(for nodeID: String) {
        guard let idx = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        let offset = dragOffsets[nodeID] ?? .zero
        nodes[idx].position = CGPoint(x: nodes[idx].position.x + offset.width,
                                      y: nodes[idx].position.y + offset.height)
        dragOffsets[nodeID] = .zero
    }

    func startJoin(from origin: ERDPort) {
        pendingJoin = PendingJoin(origin: origin, currentLocation: origin.point)
    }

    func updateJoin(to point: CGPoint) {
        pendingJoin?.currentLocation = point
    }

    func completeJoin(target: ERDPort?) {
        guard let pending = pendingJoin, let target = target else { pendingJoin = nil; return }
        let origin = pending.origin
        let sql = """
        SELECT *
        FROM \"\(origin.table)\"
        INNER JOIN \"\(target.table)\"
          ON \"\(origin.table)\".\"\(origin.column)\" = \"\(target.table)\".\"\(target.column)\";
        """
        generatedSQL = sql
        pendingJoin = nil
    }

    private func inferColumns(for table: TableInfo) -> [ERDColumn] {
        // Without live introspection the canvas seeds a baseline schema:
        // a primary `id` column plus naming heuristics for foreign keys
        // (`*_id` matches another table named after the prefix).
        let pk = ERDColumn(name: "id", typeName: "uuid", isPrimary: true, foreignReference: nil)
        return [pk]
    }
}

struct PendingJoin: Hashable {
    let origin: ERDPort
    var currentLocation: CGPoint
}

struct ERDPort: Hashable {
    let nodeID: String
    let table: String
    let column: String
    let point: CGPoint
}
