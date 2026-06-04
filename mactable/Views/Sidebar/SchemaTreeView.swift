//
//  SchemaTreeView.swift
//  mactable
//
//  Recursive navigator tree built on top of SchemaNode. Maintains its own
//  expansion state for each node ID and selection binding so multiple
//  levels of disclosure animate independently with calibrated springs.
//

import SwiftUI

struct SchemaTreeView: View {
    let roots: [SchemaNode]
    @Binding var selectedNodeID: String?
    @Binding var expandedNodeIDs: Set<String>
    let onSelectTable: (TableInfo) -> Void
    let onExpand: (SchemaNode) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(roots) { root in
                    SchemaTreeNodeView(
                        node: root,
                        depth: 0,
                        selectedNodeID: $selectedNodeID,
                        expandedNodeIDs: $expandedNodeIDs,
                        onSelectTable: onSelectTable,
                        onExpand: onExpand
                    )
                }
            }
            .padding(.vertical, 6)
        }
        .scrollContentBackground(.hidden)
    }
}

