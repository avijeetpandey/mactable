//
//  AppTheme.swift
//  mactable
//
//  Centralised semantic color palette. All views must read from AppTheme
//  rather than instantiating raw Color literals so that light/dark mode
//  and accent overrides cascade everywhere from one place.
//

import SwiftUI

enum AppTheme {
    /// Electric Indigo — the brand accent used for primary interactive elements.
    static let accent = Color(red: 0.349, green: 0.282, blue: 0.965)

    /// Soft accent fill used for hover backdrops and subtle selected states.
    static let accentSoft = Color(red: 0.349, green: 0.282, blue: 0.965).opacity(0.12)

    /// Vibrant accent reserved for focused active selection states.
    static let accentVivid = Color(red: 0.435, green: 0.357, blue: 1.0)

    /// Primary label colour — automatically mirrors `Color.primary` so it
    /// adapts to light/dark mode without manual asset catalogue work.
    static let primaryLabel = Color.primary

    /// Secondary label colour for sub-titles, metadata, and inactive copy.
    static let secondaryLabel = Color.secondary

    /// Tertiary label colour for the lightest type — placeholder text, glyph hints.
    static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)

    /// Quaternary label — used for separators rendered as text.
    static let quaternaryLabel = Color(nsColor: .quaternaryLabelColor)

    /// Sidebar background fill when material isn't appropriate.
    static let sidebarBackground = Color(nsColor: .windowBackgroundColor)

    /// Subtle row hover backdrop — deliberately neutral so it composes well
    /// over any underlying material.
    static let rowHoverBackdrop = Color.primary.opacity(0.06)

    /// Active row selection backdrop tied to the brand accent.
    static let rowSelectedBackdrop = Color(red: 0.349, green: 0.282, blue: 0.965).opacity(0.18)

    /// Striping colours for the high-density data grid (Phase 3 will consume).
    static let stripeLight = Color.black.opacity(0.03)
    static let stripeDark = Color.white.opacity(0.03)

    /// Hairline divider colour used by `InnerShadowDividerView` for the
    /// 1pt top boundary that separates the toolbar area from the content.
    static let hairline = Color.black.opacity(0.18)

    /// Mac-grade success/warn/error tokens.
    static let success = Color(red: 0.235, green: 0.706, blue: 0.412)
    static let warning = Color(red: 0.980, green: 0.741, blue: 0.310)
    static let danger  = Color(red: 0.945, green: 0.353, blue: 0.353)
}
