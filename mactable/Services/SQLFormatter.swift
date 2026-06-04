//
//  SQLFormatter.swift
//  mactable
//
//  Lightweight ANSI-SQL formatter. Inserts line breaks before major
//  clauses (SELECT, FROM, WHERE, JOIN, ORDER BY, …) and indents
//  parenthesised subqueries by two spaces. Pure value transform so it is
//  trivial to unit test.
//

import Foundation

enum SQLFormatter {

    private static let majorClauses: [String] = [
        "SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", "HAVING",
        "LIMIT", "OFFSET", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN",
        "FULL JOIN", "JOIN", "UNION ALL", "UNION", "ON"
    ]

    static func format(_ sql: String) -> String {
        var working = sql.replacingOccurrences(of: "\n", with: " ")
        working = collapseWhitespace(working)
        for clause in majorClauses {
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: clause))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(working.startIndex..., in: working)
                working = regex.stringByReplacingMatches(in: working, options: [], range: range, withTemplate: "\n\(clause)")
            }
        }
        // Indent parenthesised subqueries by 2 spaces per opening paren.
        var indent = 0
        var out = ""
        for char in working {
            if char == "(" { indent += 1 }
            if char == ")" { indent = max(0, indent - 1) }
            out.append(char)
            if char == "\n" {
                out.append(String(repeating: "  ", count: indent))
            }
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func collapseWhitespace(_ s: String) -> String {
        let regex = try! NSRegularExpression(pattern: "\\s+")
        let range = NSRange(s.startIndex..., in: s)
        return regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: " ")
    }
}
