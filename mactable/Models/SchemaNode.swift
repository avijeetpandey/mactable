//
//  SchemaNode.swift
//  mactable
//
//  A pure value-type model representing one row in the hierarchical
//  Connection → Schema → Table navigator tree. The tree is recursive but
//  bounded to three levels in Phase 1; the same structure scales to more
//  levels (databases, stored procedures) without changes to the views.
//

import Foundation

struct SchemaNode: Identifiable, Hashable {
    enum Kind: Hashable {
        case connection
        case schema
        case table(TableKind)
    }

    let id: String
    let kind: Kind
    let title: String
    let subtitle: String?
    let symbolName: String
    /// Tables in this schema (only populated for `.schema` nodes).
    let tableInfo: TableInfo?
    let children: [SchemaNode]

    var isLeaf: Bool { children.isEmpty && kind != .schema }
}
