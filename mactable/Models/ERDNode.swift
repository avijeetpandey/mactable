//
//  ERDNode.swift
//  mactable
//
//  Value-type that represents a single table node placed on the ERD
//  canvas. Position is editable (drag) but the underlying schema metadata
//  is immutable so the auto-layout engine can reason about it safely.
//

import Foundation
import CoreGraphics

struct ERDNode: Identifiable, Hashable {
    let id: String
    let table: String
    let schema: String
    let columns: [ERDColumn]
    var position: CGPoint
    var size: CGSize

    static let defaultSize = CGSize(width: 220, height: 32)
}

struct ERDColumn: Hashable {
    let name: String
    let typeName: String
    let isPrimary: Bool
    let foreignReference: ERDForeignReference?
}

struct ERDForeignReference: Hashable {
    let targetTable: String
    let targetColumn: String
}
