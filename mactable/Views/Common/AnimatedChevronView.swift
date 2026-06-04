//
//  AnimatedChevronView.swift
//  mactable
//
//  A disclosure chevron that smoothly rotates between collapsed (0°) and
//  expanded (90°) using a calibrated spring. Replaces the default
//  DisclosureGroup chevron with a Mac-grade interaction.
//

import SwiftUI

struct AnimatedChevronView: View {
    let isExpanded: Bool

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppTheme.tertiaryLabel)
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .animation(.spring(response: 0.35, dampingFraction: 0.73), value: isExpanded)
            .frame(width: 12, height: 12)
    }
}
