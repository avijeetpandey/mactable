//
//  SlowQueryRowView.swift
//  mactable
//

import SwiftUI

struct SlowQueryRowView: View {
    let query: SlowQuery

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(query.query)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.tail)
                HStack(spacing: 12) {
                    Label("\(query.calls) calls", systemImage: "number")
                    Label(String(format: "mean %.1fms", query.meanTimeMs), systemImage: "stopwatch")
                    Label(String(format: "total %.0fms", query.totalTimeMs), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            SparklineView(values: query.trend, tint: .orange)
                .frame(width: 50, height: 20)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
