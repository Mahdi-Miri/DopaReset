// GenerateWeeklyReportUseCase.swift
// Builds a WeeklyReport from raw threshold exceed events

import Foundation

struct GenerateWeeklyReportUseCase {

    private let scoreUseCase = CalculateDopamineScoreUseCase()

    func execute(
        currentEvents: [ThresholdExceedEvent],
        previousEvents: [ThresholdExceedEvent],
        monitoredApps: [MonitoredApp],
        weekStart: Date = Date().startOfWeek
    ) -> WeeklyReport {

        let weekEnd = weekStart.endOfWeek

        // Filter to current week
        let weekEvents = currentEvents.filter {
            $0.occurredAt >= weekStart && $0.occurredAt <= weekEnd
        }

        // Most used app (most events)
        let appFrequency = Dictionary(grouping: weekEvents, by: \.appDisplayName)
            .mapValues(\.count)
        let mostUsed = appFrequency.max(by: { $0.value < $1.value })?.key ?? "None"

        // Total minutes over threshold
        let totalMinutes = weekEvents.reduce(0) { $0 + $1.minutesOverThreshold }

        // Daily breakdown
        let dailyData: [WeeklyReport.DailyDataPoint] = Date.lastSevenDays().map { day in
            let dayStart = day.startOfDay
            let dayEnd   = day.endOfDay
            let dayEvents = weekEvents.filter { $0.occurredAt >= dayStart && $0.occurredAt <= dayEnd }
            let mins      = dayEvents.reduce(0) { $0 + $1.minutesOverThreshold }
            return WeeklyReport.DailyDataPoint(date: day, exceedCount: dayEvents.count, minutesOver: mins)
        }

        // Dopamine score
        let score = scoreUseCase.execute(events: weekEvents, totalApps: max(monitoredApps.count, 1))

        // Trend: compare event counts
        let prevCount    = previousEvents.count
        let currentCount = weekEvents.count
        var trend: Int   = 0
        if prevCount > 0 {
            trend = Int(((Double(prevCount - currentCount) / Double(prevCount)) * 100).rounded())
        } else if currentCount == 0 {
            trend = 0
        } else {
            trend = -100
        }

        return WeeklyReport(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalExceedEvents: weekEvents.count,
            totalMinutesOverThreshold: totalMinutes,
            mostUsedAppName: mostUsed,
            dopamineScore: score,
            dailyBreakdown: dailyData,
            trendVsLastWeek: trend
        )
    }
}
