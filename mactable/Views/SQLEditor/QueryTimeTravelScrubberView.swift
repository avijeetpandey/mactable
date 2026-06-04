//
//  QueryTimeTravelScrubberView.swift
//  mactable
//
//  Horizontal interaction track surfacing the last 10 executed queries.
//  Two-finger horizontal scroll or arrow-key nav steps through cached
//  results without re-running the network round-trip.
//

import SwiftUI

struct QueryTimeTravelScrubberView: View {
    @ObservedObject var viewModel: QueryEditorViewModel

    var body: some View {
        if viewModel.history.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("Time Travel")
                    .font(AppTypography.metadata(11).weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryLabel)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(viewModel.history.enumerated()), id: \.element.id) { idx, entry in
                            chip(entry: entry, idx: idx, isActive: viewModel.historyIndex == idx)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.73)) {
                                        viewModel.loadHistory(at: idx)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                Spacer()
                Text("\(viewModel.history.count) / 10")
                    .font(AppTypography.metadata(10))
                    .foregroundStyle(AppTheme.tertiaryLabel)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private func chip(entry: QueryHistoryEntry, idx: Int, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(snippet(of: entry.sql))
                .font(AppTypography.mono(10))
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(spacing: 3) {
                Text("\(entry.result.rows.count)r")
                    .font(AppTypography.metadata(9))
                    .foregroundStyle(AppTheme.tertiaryLabel)
                Text("·").foregroundStyle(AppTheme.tertiaryLabel)
                Text("\(Int(entry.result.executionTime * 1000))ms")
                    .font(AppTypography.metadata(9))
                    .foregroundStyle(AppTheme.tertiaryLabel)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: 130, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? AppTheme.accentSoft : AppTheme.rowHoverBackdrop.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? AppTheme.accent : .clear, lineWidth: 1)
        )
    }

    private func snippet(of sql: String) -> String {
        let collapsed = sql.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        return String(collapsed.prefix(40))
    }
}
