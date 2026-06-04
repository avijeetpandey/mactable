//
//  EditableGridCellView.swift
//  mactable
//
//  Single grid cell that swaps between a mono-typed Text representation
//  and an inline TextField on double-click. Coordinates with the shared
//  `MutationsQueue` so committed edits are batched under Safe-Mode.
//

import SwiftUI

struct EditableGridCellView: View {
    let value: CellValue
    let pendingValue: CellValue?
    let isPrimaryKey: Bool
    let onSubmit: (String) -> Void
    @State private var isEditing: Bool = false
    @State private var draft: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(AppTypography.mono(12))
                    .focused($fieldFocused)
                    .onSubmit { commit() }
                    .onAppear { fieldFocused = true }
                    .onExitCommand { isEditing = false }
            } else {
                HStack(spacing: 4) {
                    if pendingValue != nil {
                        Circle()
                            .fill(AppTheme.warning)
                            .frame(width: 5, height: 5)
                    }
                    Text(displayText)
                        .font(AppTypography.mono(12))
                        .foregroundStyle(displayedColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard !isPrimaryKey else { return }
            draft = (pendingValue ?? value).displayString
            isEditing = true
        }
    }

    private var displayText: String {
        let effective = pendingValue ?? value
        if case .null = effective { return "NULL" }
        return effective.displayString
    }

    private var displayedColor: Color {
        if case .null = value, pendingValue == nil { return AppTheme.tertiaryLabel }
        if pendingValue != nil { return AppTheme.warning }
        return AppTheme.primaryLabel
    }

    private func commit() {
        isEditing = false
        onSubmit(draft)
    }
}
