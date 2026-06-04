//
//  MarkdownRenderer.swift
//  mactable
//
//  Bridges raw markdown to a SwiftUI-friendly `AttributedString` using
//  Apple's built-in Markdown parser. Falls back to plain text on errors so
//  the inspector remains usable on malformed input.
//

import Foundation

enum MarkdownRenderer {
    static func render(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown,
                                        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full))
        } catch {
            return AttributedString(markdown)
        }
    }
}
