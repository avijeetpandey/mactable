//
//  InnerShadowDividerView.swift
//  mactable
//
//  A 1-point hairline that renders an inner top shadow, used to crisply
//  separate the floating toolbar area from the content pane. The shadow
//  is intentionally one-sided (top-only) so it reads as a recessed edge.
//

import SwiftUI

struct InnerShadowDividerView: View {
    var body: some View {
        ZStack(alignment: .top) {
            AppTheme.hairline
                .frame(height: 1)
            LinearGradient(
                colors: [Color.black.opacity(0.20), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 4)
            .blendMode(.plusDarker)
        }
        .frame(height: 4)
        .allowsHitTesting(false)
    }
}
