//
//  ScratchpadInspectorView.swift
//  mactable
//
//  Native macOS inspector drawer (`.inspector(...)`) hosting a per-
//  connection markdown scratchpad. Notes are persisted to the SwiftData
//  store keyed by connection ID so DBA runbooks travel with the profile.
//

import SwiftUI
import SwiftData

struct ScratchpadInspectorView: View {
    let connectionID: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [ScratchpadNote]
    @State private var draft: String = ""
    @State private var preview: Bool = false

    private var note: ScratchpadNote? {
        notes.first(where: { $0.connectionID == connectionID })
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundStyle(AppTheme.accent)
                Text("Scratchpad")
                    .font(AppTypography.headline(13))
                Spacer()
                Picker("", selection: $preview) {
                    Text("Edit").tag(false)
                    Text("Preview").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            Divider().opacity(0.2)

            if preview {
                ScrollView {
                    Text(MarkdownRenderer.render(draft))
                        .font(AppTypography.body(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(14)
                }
            } else {
                TextEditor(text: $draft)
                    .font(AppTypography.mono(12))
                    .padding(8)
                    .scrollContentBackground(.hidden)
            }

            Divider().opacity(0.2)
            HStack {
                Text(note?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "Unsaved")
                    .font(AppTypography.metadata(10))
                    .foregroundStyle(AppTheme.tertiaryLabel)
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(HoverableButtonStyle(tint: AppTheme.accent))
                    .controlSize(.small)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .onAppear { draft = note?.markdown ?? defaultMarkdown }
    }

    private var defaultMarkdown: String {
        """
        # Notes

        - Investigate slow queries on `movies` table
        - Migration plan for staging
        - **Tip:** Use ⌘K to jump between tables.
        """
    }

    private func save() {
        if let existing = note {
            existing.markdown = draft
            existing.updatedAt = Date()
        } else {
            let new = ScratchpadNote(connectionID: connectionID, markdown: draft, updatedAt: Date())
            modelContext.insert(new)
        }
        try? modelContext.save()
    }
}
