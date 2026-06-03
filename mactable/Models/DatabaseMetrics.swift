//
//  DatabaseMetrics.swift
//  mactable
//

import Foundation

struct DatabaseMetrics: Hashable {
    var activeConnections: Int
    var totalConnections: Int
    var databaseSizeBytes: Int64
    var uptimeSeconds: Int64
    var slowestQueries: [SlowQuery]
    var historicalConnections: [TimeSeriesPoint]
    var historicalQPS: [TimeSeriesPoint]

    static let empty = DatabaseMetrics(
        activeConnections: 0,
        totalConnections: 0,
        databaseSizeBytes: 0,
        uptimeSeconds: 0,
        slowestQueries: [],
        historicalConnections: [],
        historicalQPS: []
    )
}

struct SlowQuery: Hashable, Identifiable {
    let id = UUID()
    let query: String
    let totalTimeMs: Double
    let calls: Int
    let meanTimeMs: Double
    let trend: [Double]
}

struct TimeSeriesPoint: Hashable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}
