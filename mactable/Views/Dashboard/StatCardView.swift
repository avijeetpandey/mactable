//
//  StatCardView.swift
//  mactable
//

import SwiftUI
import Charts

struct StatCardView: View {
    let title: String
    let value: String
    let trend: [Double]
    let icon: String
    let tint: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                SparklineView(values: trend, tint: tint)
                    .frame(width: 50, height: 20)
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(tint.opacity(isHovered ? 0.45 : 0.18), lineWidth: 1))
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct SparklineView: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { idx, val in
            LineMark(x: .value("i", idx), y: .value("v", val))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            AreaMark(x: .value("i", idx), y: .value("v", val))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.background(Color.clear) }
    }
}
