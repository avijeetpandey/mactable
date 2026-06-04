//
//  SchemaTreeNodeView.swift
//  mactable
//
//  A single recursive node within the schema navigator tree. Lives as its
//  own value-type struct so SwiftUI can resolve the opaque `some View`
//  return type without recursive inference (a sibling helper function
//  inside SchemaTreeView would otherwise self-reference its return type).
//

import SwiftUI

struct SchemaTreeNodeView: View {
    let node: SchemaNode
    let depth: Int
    @Binding var selectedNodeID: String?
    @Binding var expandedNodeIDs: Set<String>
    let onSelectTable: (TableInfo) -> Void
    let onExpand: (SchemaNode) -> Void

    var body: some View {
        let expanded = expandedNodeIDs.contains(node.id)
        let selected = selectedNodeID == node.id

        VStack(alignment: .leading, spacing: 1) {
            SchemaNodeRowView(
                node: node,
                depth: depth,
                isExpanded: expanded,
                isSelected: selected,
                onToggle: toggle,
                onSelect: select
            )

            if expanded {
                ForEach(node.children) { child in
                    SchemaTreeNodeView(
                        node: child,
                        depth: depth + 1,
                        selectedNodeID: $selectedNodeID,
                        expandedNodeIDs: $expandedNodeIDs,
                        onSelectTable: onSelectTable,
                        onExpand: onExpand
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.73), value: expanded)
    }

    private func toggle() {
        if expandedNodeIDs.contains(node.id) {
            expandedNodeIDs.remove(node.id)
        } else {
            expandedNodeIDs.insert(node.id)
            onExpand(node)
        }
    }

    private func select() {
        selectedNodeID = node.id
        if case .table = node.kind, let info = node.tableInfo {
            onSelectTable(info)
        }
    }
}
