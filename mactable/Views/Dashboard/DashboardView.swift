//
//  DashboardView.swift
//  mactable
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var session: ConnectionSession
    @StateObject private var viewModel: DashboardViewModel

    init(session: ConnectionSession) {
        self.session = session
        _viewModel = StateObject(wrappedValue: DashboardViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statCardsGrid
                connectionsChart
                slowQueriesPanel
            }
            .padding(20)
        }
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }

    private var statCardsGrid: some View {
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                StatCardView(title: "Active Connections",
                             value: "\(viewModel.metrics.activeConnections)",
                             trend: viewModel.metrics.historicalConnections.map { $0.value },
                             icon: "bolt.fill", tint: .green)
                StatCardView(title: "Total Connections",
                             value: "\(viewModel.metrics.totalConnections)",
                             trend: viewModel.metrics.historicalConnections.map { $0.value },
                             icon: "person.3.fill", tint: .blue)
            }
            GridRow {
                StatCardView(title: "Database Size",
                             value: ByteCountFormatter.string(fromByteCount: viewModel.metrics.databaseSizeBytes, countStyle: .binary),
                             trend: viewModel.metrics.historicalQPS.map { $0.value },
                             icon: "externaldrive.fill", tint: .purple)
                StatCardView(title: "Uptime",
                             value: formatUptime(viewModel.metrics.uptimeSeconds),
                             trend: viewModel.metrics.historicalQPS.map { $0.value },
                             icon: "clock.fill", tint: .orange)
            }
        }
    }

    private var connectionsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Connections (last 30 min)")
                .font(.system(.headline, design: .rounded, weight: .semibold))
            Chart(viewModel.metrics.historicalConnections) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Connections", point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.4)],
                                                startPoint: .leading, endPoint: .trailing))
                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Connections", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [.accentColor.opacity(0.35), .clear],
                                                startPoint: .top, endPoint: .bottom))
            }
            .frame(height: 220)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary, lineWidth: 1))
        }
    }

    private var slowQueriesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Slowest Queries")
                .font(.system(.headline, design: .rounded, weight: .semibold))
            if viewModel.metrics.slowestQueries.isEmpty {
                EmptyStateView(symbol: "tortoise", title: "No Slow Queries",
                               message: "pg_stat_statements not enabled or no recorded queries.")
                    .frame(height: 140)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.metrics.slowestQueries) { q in
                        SlowQueryRowView(query: q)
                        Divider().opacity(0.2)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary, lineWidth: 1))
            }
        }
    }

    private func formatUptime(_ seconds: Int64) -> String {
        let h = seconds / 3600
        let d = h / 24
        if d > 0 { return "\(d)d \(h % 24)h" }
        if h > 0 { return "\(h)h \((seconds % 3600) / 60)m" }
        return "\(seconds / 60)m"
    }
}
