//
//  ERDLayoutEngine.swift
//  mactable
//
//  Pure auto-layout solver that arranges ERD nodes on a grid using a
//  cheap force-free constraint pass: nodes are sorted by foreign-key
//  in-degree (parents first) and placed in alphabetised columns. This
//  yields a stable, collision-free baseline that the user can refine
//  manually by dragging individual nodes.
//

import Foundation
import CoreGraphics

enum ERDLayoutEngine {

    static func layout(_ nodes: [ERDNode],
                       canvasSize: CGSize = CGSize(width: 1600, height: 1200)) -> [ERDNode] {
        let inDegree: [String: Int] = nodes.reduce(into: [:]) { acc, node in
            for col in node.columns {
                if let ref = col.foreignReference {
                    acc[ref.targetTable, default: 0] += 1
                }
            }
        }

        let sorted = nodes.sorted { lhs, rhs in
            let lDeg = inDegree[lhs.table] ?? 0
            let rDeg = inDegree[rhs.table] ?? 0
            if lDeg != rDeg { return lDeg > rDeg }
            return lhs.table < rhs.table
        }

        let columns = max(1, Int(Double(sorted.count).squareRoot().rounded(.up)))
        let cellWidth: CGFloat = 280
        let cellHeight: CGFloat = 320
        let originX: CGFloat = 60
        let originY: CGFloat = 60

        var positioned: [ERDNode] = []
        for (idx, node) in sorted.enumerated() {
            var copy = node
            let row = idx / columns
            let col = idx % columns
            copy.position = CGPoint(
                x: originX + CGFloat(col) * cellWidth,
                y: originY + CGFloat(row) * cellHeight
            )
            let height = ERDNode.defaultSize.height + CGFloat(node.columns.count) * 22 + 16
            copy.size = CGSize(width: ERDNode.defaultSize.width, height: height)
            positioned.append(copy)
        }
        return positioned
    }
}
