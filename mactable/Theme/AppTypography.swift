//
//  AppTypography.swift
//  mactable
//
//  Semantic Apple-grade typography helpers. Use these factories rather than
//  inline `.font(.system(...))` calls so that grading and weight choices
//  stay consistent across screens.
//

import SwiftUI

enum AppTypography {
    /// Heavy SF Pro Rounded — reserved for stat numbers and dashboard KPIs.
    static func statNumber(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }

    /// Bold rounded — section headlines (e.g. sidebar branding, sheet titles).
    static func headline(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Semibold control label — segmented controls, primary buttons.
    static func control(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// Medium body — the default for sidebar items and inspectors.
    static func body(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Caption secondary — host:port subtitles, metadata.
    static func metadata(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// SF Mono fixed-width — the *only* font allowed in the data grid and SQL editor.
    static func mono(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
