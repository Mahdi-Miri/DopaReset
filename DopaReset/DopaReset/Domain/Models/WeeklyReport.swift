// WeeklyReport.swift
// Domain model for the weekly usage report

import Foundation

struct WeeklyReport: Equatable {

    struct DailyDataPoint: Identifiable, Equatable {
        let id: UUID = UUID()
        let date: Date
        let exceedCount: Int
        let minutesOver: Int
    }

    let weekStartDate: Date
    let weekEndDate: Date

    let totalExceedEvents: Int
    let totalMinutesOverThreshold: Int
    let mostUsedAppName: String
    let dopamineScore: Int           // 0–100; higher = better control
    let dailyBreakdown: [DailyDataPoint]

    // Trend: positive = improved vs previous week, negative = worse
    let trendVsLastWeek: Int        // percentage delta, e.g. +12 means 12% fewer events

    var weekRangeLabel: String {
        weekStartDate.weekRange
    }

    var dopamineScoreLabel: String {
        switch dopamineScore {
        case 80...100: return "Excellent 🌟"
        case 60...79:  return "Good 👍"
        case 40...59:  return "Fair 🤔"
        case 20...39:  return "Poor ⚠️"
        default:       return "Critical 🚨"
        }
    }

    var trendEmoji: String {
        trendVsLastWeek >= 0 ? "📈" : "📉"
    }

    var trendLabel: String {
        let abs = abs(trendVsLastWeek)
        if trendVsLastWeek == 0  { return "Same as last week" }
        if trendVsLastWeek > 0   { return "\(abs)% better than last week \(trendEmoji)" }
        return "\(abs)% worse than last week \(trendEmoji)"
    }
}
