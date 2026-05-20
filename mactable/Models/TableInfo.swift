//
//  TableInfo.swift
//  mactable
//

import Foundation

struct TableInfo: Identifiable, Hashable {
    let id: String
    let schema: String
    let name: String
    let kind: TableKind
    let estimatedRows: Int?

    var displayName: String {
        schema.isEmpty ? name : "\(schema).\(name)"
    }
}

enum TableKind: String, Hashable {
    case table
    case view
    case collection
    case materializedView

    var symbolName: String {
        switch self {
        case .table:            return "tablecells"
        case .view:             return "rectangle.stack"
        case .collection:       return "doc.text.fill"
        case .materializedView: return "rectangle.stack.fill"
        }
    }
}
