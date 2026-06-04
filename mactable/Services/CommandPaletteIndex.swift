//
//  CommandPaletteIndex.swift
//  mactable
//
//  Pure value-type fuzzy index that powers the Cmd+K palette. Indexing is
//  side-effect free so it is fully unit-testable; the host view passes in
//  the latest snapshot of saved connections, sessions, and saved queries
//  on every keystroke.
//

import Foundation

struct CommandPaletteIndex {
    let items: [CommandPaletteItem]

    func search(_ query: String, limit: Int = 40) -> [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return Array(items.prefix(limit))
        }
        let scored: [(CommandPaletteItem, Int)] = items.compactMap { item in
            guard let score = Self.score(item: item, query: trimmed) else { return nil }
            return (item, score)
        }
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    /// Cheap fuzzy ranking: exact prefix > substring > subsequence over
    /// `title` and `keywords`. Returns nil if no signal at all.
    static func score(item: CommandPaletteItem, query: String) -> Int? {
        let title = item.title.lowercased()
        if title == query { return 1000 }
        if title.hasPrefix(query) { return 800 }
        if title.contains(query) { return 600 }
        for kw in item.keywords {
            let k = kw.lowercased()
            if k == query { return 500 }
            if k.hasPrefix(query) { return 400 }
            if k.contains(query) { return 300 }
        }
        if isSubsequence(query, of: title) { return 200 }
        return nil
    }

    private static func isSubsequence(_ needle: String, of haystack: String) -> Bool {
        var hi = haystack.startIndex
        for ch in needle {
            while hi < haystack.endIndex, haystack[hi] != ch {
                hi = haystack.index(after: hi)
            }
            if hi == haystack.endIndex { return false }
            hi = haystack.index(after: hi)
        }
        return true
    }
}
