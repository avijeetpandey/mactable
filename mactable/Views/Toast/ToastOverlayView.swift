//
//  ToastOverlayView.swift
//  mactable
//

import SwiftUI

struct ToastOverlayView: View {
    @EnvironmentObject private var center: ToastCenter

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(center.toasts) { toast in
                ToastBannerView(toast: toast)
                    .onTapGesture { center.dismiss(toast.id) }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
            }
        }
        .frame(maxWidth: 360, alignment: .trailing)
        .allowsHitTesting(true)
    }
}

struct ToastBannerView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.kind.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(toast.kind.tint)
            Text(toast.message)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(toast.kind.tint.opacity(0.25), lineWidth: 1)
        )
    }
}
