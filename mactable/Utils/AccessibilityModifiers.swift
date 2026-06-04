//
//  AccessibilityModifiers.swift
//  mactable
//
//  Reusable accessibility helpers ensuring VoiceOver labels and traits
//  are applied uniformly across the codebase. Phase-7 spec mandates
//  explicit descriptions on every interactive container.
//

import SwiftUI

extension View {
    /// Apply a standardised accessibility label, hint, and trait set for
    /// primary action buttons.
    func accessibleAction(label: String, hint: String? = nil) -> some View {
        self.accessibilityLabel(Text(label))
            .accessibilityHint(Text(hint ?? ""))
            .accessibilityAddTraits(.isButton)
    }

    /// Mark the view as a static text region with a description suitable
    /// for VoiceOver rotor navigation.
    func accessibleStaticText(_ text: String) -> some View {
        self.accessibilityLabel(Text(text))
            .accessibilityAddTraits(.isStaticText)
    }
}
