//
//  SQLAnalyzer.swift
//  mactable
//
//  Best-effort regex parser that pulls the primary table name out of a
//  SQL statement so the data grid can target inline edits at the right
//  table without a full ANTLR-class parser.
//

import Foundation

enum SQLAnalyzer {

    /// Returns the first table name in a `FROM` / `UPDATE` / `INSERT INTO`
    /// clause, stripping surrounding quotes and schema prefixes.
    static func tableName(in sql: String) -> String? {
        let patterns = [
            #"FROM\s+([\w."`]+)"#,
            #"UPDATE\s+([\w."`]+)"#,
            #"INTO\s+([\w."`]+)"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let nsSQL = sql as NSString
            let fullRange = NSRange(location: 0, length: nsSQL.length)
            guard let match = regex.firstMatch(in: sql, range: fullRange),
                  match.numberOfRanges > 1 else { continue }
            let raw = nsSQL.substring(with: match.range(at: 1))
            return cleanIdentifier(raw)
        }
        return nil
    }

    private static func cleanIdentifier(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"`'"))
        if let dot = trimmed.lastIndex(of: ".") {
            let after = trimmed.index(after: dot)
            return String(trimmed[after...]).trimmingCharacters(in: CharacterSet(charactersIn: "\"`'"))
        }
        return trimmed
    }
}
