//
//  SQLCodeView.swift
//  mactable
//
//  NSTextView-backed editor with SF Mono, syntax highlighting, and inline autocomplete.
//

import SwiftUI
import AppKit

struct SQLCodeView: NSViewRepresentable {
    @Binding var text: String
    let keywords: [String]
    let tableNames: [String]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = NSColor(calibratedWhite: 0.07, alpha: 0.0)
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 14, height: 12)
        textView.textColor = NSColor.labelColor
        textView.usesFindBar = true
        textView.string = text
        context.coordinator.textView = textView
        context.coordinator.applyHighlight()
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.applyHighlight()
        }
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SQLCodeView
        weak var textView: NSTextView?

        init(_ parent: SQLCodeView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
            applyHighlight()
        }

        func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>?) -> [String] {
            let nsString = textView.string as NSString
            let prefix = nsString.substring(with: charRange).lowercased()
            let candidates = parent.keywords + parent.tableNames
            return candidates.filter { $0.lowercased().hasPrefix(prefix) }.sorted()
        }

        func applyHighlight() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let full = tv.string as NSString
            let fullRange = NSRange(location: 0, length: full.length)
            storage.beginEditing()
            storage.setAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ], range: fullRange)

            // Keywords
            let keywordPattern = "\\b(" + parent.keywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")\\b"
            highlight(pattern: keywordPattern, color: NSColor.systemPurple, weight: .semibold, in: storage, range: fullRange, options: [.caseInsensitive])
            // Strings
            highlight(pattern: "'([^'\\\\]|\\\\.)*'", color: NSColor.systemRed, weight: .regular, in: storage, range: fullRange)
            highlight(pattern: "\"([^\"\\\\]|\\\\.)*\"", color: NSColor.systemRed, weight: .regular, in: storage, range: fullRange)
            // Numbers
            highlight(pattern: "\\b\\d+(\\.\\d+)?\\b", color: NSColor.systemTeal, weight: .regular, in: storage, range: fullRange)
            // Comments
            highlight(pattern: "--[^\\n]*", color: NSColor.secondaryLabelColor, weight: .regular, in: storage, range: fullRange)
            highlight(pattern: "/\\*[\\s\\S]*?\\*/", color: NSColor.secondaryLabelColor, weight: .regular, in: storage, range: fullRange)

            storage.endEditing()
        }

        private func highlight(pattern: String, color: NSColor, weight: NSFont.Weight,
                               in storage: NSTextStorage, range: NSRange,
                               options: NSRegularExpression.Options = []) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            regex.enumerateMatches(in: storage.string, options: [], range: range) { match, _, _ in
                guard let m = match else { return }
                storage.addAttributes([
                    .foregroundColor: color,
                    .font: NSFont.monospacedSystemFont(ofSize: 13, weight: weight)
                ], range: m.range)
            }
        }
    }
}
