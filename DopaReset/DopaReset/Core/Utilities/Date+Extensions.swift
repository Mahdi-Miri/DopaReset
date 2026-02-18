// Date+Extensions.swift
// Handy date helpers used across the app

import Foundation

extension Date {

    // MARK: - Week boundaries

    /// Start of the current calendar week (Monday)
    var startOfWeek: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the current calendar week (Sunday 23:59:59)
    var endOfWeek: Date {
        startOfWeek.addingTimeInterval(7 * 24 * 60 * 60 - 1)
    }

    // MARK: - Day boundaries

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        startOfDay.addingTimeInterval(24 * 60 * 60 - 1)
    }

    // MARK: - Time of day helpers

    enum TimeOfDay: String, CaseIterable {
        case morning   = "Morning"   // 05:00 – 11:59
        case afternoon = "Afternoon" // 12:00 – 16:59
        case evening   = "Evening"   // 17:00 – 20:59
        case night     = "Night"     // 21:00 – 04:59
    }

    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 5...11:  return .morning
        case 12...16: return .afternoon
        case 17...20: return .evening
        default:      return .night
        }
    }

    // MARK: - Formatting

    func formatted(as format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }

    var shortDayName: String { formatted(as: "EEE") }
    var dayNumber: String    { formatted(as: "d") }
    var weekRange: String {
        let end = endOfWeek
        let startStr = formatted(as: "MMM d")
        let endStr   = end.formatted(as: "MMM d, yyyy")
        return "\(startStr) – \(endStr)"
    }

    // MARK: - Seven day array

    static func lastSevenDays() -> [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: Date())
        }.reversed()
    }
}
