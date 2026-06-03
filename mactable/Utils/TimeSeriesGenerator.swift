//
//  TimeSeriesGenerator.swift
//  mactable
//

import Foundation

enum TimeSeriesGenerator {
    static func recent(seed: Double, points: Int) -> [TimeSeriesPoint] {
        let now = Date()
        var values: [TimeSeriesPoint] = []
        var v = max(seed, 1)
        for i in (0..<points).reversed() {
            let drift = Double.random(in: -0.15...0.15) * v
            v = max(0, v + drift)
            values.append(TimeSeriesPoint(timestamp: now.addingTimeInterval(TimeInterval(-i * 60)), value: v))
        }
        return values
    }
}
