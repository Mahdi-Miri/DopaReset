// ReportsView.swift
// Weekly report screen with Swift Charts visualisations

import SwiftUI
import Charts

struct ReportsView: View {

    @EnvironmentObject var userRepository: UserRepository
    @StateObject private var viewModel: ReportsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(userRepository: UserRepository()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else if let report = viewModel.weeklyReport {
                    ScrollView {
                        VStack(spacing: 20) {
                            weekRangeHeader(report: report)
                            statsRow(report: report)
                            chartCard(report: report)
                            dopamineScoreCard(report: report)
                            trendCard(report: report)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Week Range Header

    private func weekRangeHeader(report: WeeklyReport) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week").font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase).kerning(1)
                    Text(report.weekRangeLabel).font(.headline).foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(Color.dopaLavender)
            }
        }
    }

    // MARK: - Stats Row

    private func statsRow(report: WeeklyReport) -> some View {
        HStack(spacing: 12) {
            StatCard(
                label: "Alerts",
                value: "\(report.totalExceedEvents)",
                icon: "bell.badge.fill",
                color: .dopaCoral
            )
            StatCard(
                label: "Min Over",
                value: "\(report.totalMinutesOverThreshold)",
                icon: "clock.badge.exclamationmark.fill",
                color: .orange
            )
            StatCard(
                label: "Top App",
                value: String(report.mostUsedAppName.prefix(8)),
                icon: "app.fill",
                color: .dopaLavender
            )
        }
    }

    // MARK: - Chart Card

    private func chartCard(report: WeeklyReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Alerts")
                    .font(.headline).foregroundStyle(.white)

                Chart(report.dailyBreakdown) { point in
                    BarMark(
                        x: .value("Day", point.date.shortDayName),
                        y: .value("Alerts", point.exceedCount)
                    )
                    .foregroundStyle(Color.dopaPurpleGradient)
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str).foregroundStyle(.white.opacity(0.7)).font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let int = value.as(Int.self) {
                                Text("\(int)").foregroundStyle(.white.opacity(0.7)).font(.caption)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                    }
                }

                // Minutes over threshold line chart overlay
                Chart(report.dailyBreakdown) { point in
                    LineMark(
                        x: .value("Day", point.date.shortDayName),
                        y: .value("Min Over", point.minutesOver)
                    )
                    .foregroundStyle(Color.dopaCoral)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Day", point.date.shortDayName),
                        y: .value("Min Over", point.minutesOver)
                    )
                    .foregroundStyle(Color.dopaCoral.opacity(0.15))
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str).foregroundStyle(.white.opacity(0.7)).font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let int = value.as(Int.self) {
                                Text("\(int)m").foregroundStyle(.white.opacity(0.7)).font(.caption)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                    }
                }

                HStack(spacing: 16) {
                    LegendDot(color: .dopaPurple, label: "Alerts")
                    LegendDot(color: .dopaCoral, label: "Min over threshold")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Dopamine Score Card

    private func dopamineScoreCard(report: WeeklyReport) -> some View {
        AccentGlassCard(gradient: Color.dopaPurpleGradient) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dopamine Score")
                        .font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase).kerning(1)

                    Text("\(report.dopamineScore)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(report.dopamineScoreLabel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                // Gauge chart
                Gauge(value: Double(report.dopamineScore), in: 0...100) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.dopaCoral, .yellow, .dopaMint]))
                .scaleEffect(1.4)
                .frame(width: 80, height: 80)
            }
        }
    }

    // MARK: - Trend Card

    private func trendCard(report: WeeklyReport) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                Text(report.trendEmoji).font(.largeTitle)
                VStack(alignment: .leading, spacing: 4) {
                    Text("vs Last Week").font(.caption).foregroundStyle(.white.opacity(0.6))
                    Text(report.trendLabel).font(.headline).foregroundStyle(.white)
                }
                Spacer()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("📊").font(.system(size: 64))
            Text("No data yet").font(.title3).bold().foregroundStyle(.white)
            Text("Start using DopaReset to see your weekly report.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Sub-components

private struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(color).font(.title3)
                Text(value).font(.title3).bold().foregroundStyle(.white)
                Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .environmentObject(UserRepository())
        .environmentObject(PremiumManager())
}
