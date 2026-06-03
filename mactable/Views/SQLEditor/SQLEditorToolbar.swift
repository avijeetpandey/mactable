//
//  SQLEditorToolbar.swift
//  mactable
//

import SwiftUI

struct SQLEditorToolbar: View {
    @ObservedObject var viewModel: QueryEditorViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.run()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isExecuting ? "stop.fill" : "play.fill")
                    Text(viewModel.isExecuting ? "Running…" : "Run")
                    Text("⌘⏎")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))
                }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(HoverableButtonStyle(tint: .green))
            .disabled(viewModel.isExecuting)

            Toggle(isOn: $viewModel.safeMode) {
                Label("Safe Mode", systemImage: viewModel.safeMode ? "lock.shield.fill" : "lock.open")
                    .font(.system(.callout, design: .rounded))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Spacer()

            if viewModel.result.executionTime > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(Int(viewModel.result.executionTime * 1000)) ms")
                        .font(.system(.caption, design: .monospaced))
                        .monospacedDigit()
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(viewModel.result.rows.count) rows")
                        .font(.system(.caption, design: .monospaced))
                        .monospacedDigit()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
