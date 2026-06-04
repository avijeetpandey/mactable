//
//  CommandPaletteView.swift
//  mactable
//
//  Raycast-style centred modal palette.
//

import SwiftUI

struct CommandPaletteView: View {
    @ObservedObject var controller: CommandPaletteController
    @State private var selectedIndex: Int = 0
    @FocusState private var fieldFocused: Bool
    @Namespace private var highlightNS

    private var results: [CommandPaletteItem] {
        controller.index.search(controller.query)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider().opacity(0.25)
            resultList
        }
        .frame(width: 620, height: 460)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.hairline, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        .onAppear { fieldFocused = true; selectedIndex = 0 }
        .onChange(of: controller.query) { _, _ in selectedIndex = 0 }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "command")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            TextField("Search tables, connections, actions…", text: $controller.query)
                .textFieldStyle(.plain)
                .font(AppTypography.mono(15, weight: .regular))
                .focused($fieldFocused)
                .onSubmit { invokeSelected() }
            if !controller.query.isEmpty {
                Button {
                    controller.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.tertiaryLabel)
                }
                .buttonStyle(.plain)
            }
            Text("ESC")
                .font(AppTypography.metadata(10))
                .foregroundStyle(AppTheme.tertiaryLabel)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(AppTheme.rowHoverBackdrop))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(KeyEventCatcher(
            onArrowDown: { moveSelection(by: 1) },
            onArrowUp:   { moveSelection(by: -1) },
            onReturn:    { invokeSelected() },
            onEscape:    { controller.dismiss() }
        ).frame(width: 0, height: 0))
    }

    private var resultList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if results.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, item in
                            paletteRow(item: item, isSelected: idx == selectedIndex)
                                .id(item.id)
                                .onTapGesture { selectedIndex = idx; invokeSelected() }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .onChange(of: selectedIndex) { _, new in
                guard new < results.count else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(results[new].id, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func paletteRow(item: CommandPaletteItem, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(symbolTint(for: item.kind))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(AppTypography.body(13))
                if let sub = item.subtitle {
                    Text(sub)
                        .font(AppTypography.metadata(11))
                        .foregroundStyle(AppTheme.secondaryLabel)
                }
            }
            Spacer()
            Text(badgeLabel(for: item.kind))
                .font(AppTypography.metadata(10))
                .foregroundStyle(AppTheme.secondaryLabel)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(AppTheme.rowHoverBackdrop))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.accentSoft)
                        .matchedGeometryEffect(id: "palette.selection", in: highlightNS)
                }
            }
        )
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppTheme.tertiaryLabel)
            Text("No matches").font(AppTypography.headline(15))
            Text("Try a table name, connection, or an action like 'safe mode'.")
                .font(AppTypography.metadata(12))
                .foregroundStyle(AppTheme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func moveSelection(by delta: Int) {
        guard !results.isEmpty else { return }
        var next = selectedIndex + delta
        if next < 0 { next = results.count - 1 }
        if next >= results.count { next = 0 }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            selectedIndex = next
        }
    }

    private func invokeSelected() {
        guard selectedIndex < results.count else { return }
        controller.invoke(results[selectedIndex])
    }

    private func symbolTint(for kind: CommandPaletteItem.Kind) -> Color {
        switch kind {
        case .table:           return AppTheme.accent
        case .savedConnection: return .green
        case .savedQuery:      return .orange
        case .action:          return .blue
        case .schema:          return .purple
        }
    }

    private func badgeLabel(for kind: CommandPaletteItem.Kind) -> String {
        switch kind {
        case .table:           return "Table"
        case .savedConnection: return "Conn"
        case .savedQuery:      return "Query"
        case .action:          return "Action"
        case .schema:          return "Schema"
        }
    }
}
