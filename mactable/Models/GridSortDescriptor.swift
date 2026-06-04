//
//  GridSortDescriptor.swift
//  mactable
//
//  Describes the sort state of a single grid column. Apple-grade tables
//  cycle: unsorted → ascending → descending → unsorted on header click.
//

import Foundation

struct GridSortDescriptor: Hashable {
    enum Direction: Hashable { case ascending, descending }
    let columnID: UUID
    let direction: Direction
}

extension GridSortDescriptor {
    func next() -> GridSortDescriptor? {
        switch direction {
        case .ascending:  return GridSortDescriptor(columnID: columnID, direction: .descending)
        case .descending: return nil
        }
    }
}
