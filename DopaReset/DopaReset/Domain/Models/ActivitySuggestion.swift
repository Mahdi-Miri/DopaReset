// ActivitySuggestion.swift
// Domain model representing a suggested healthy activity

import Foundation

struct ActivitySuggestion: Equatable {
    let activity: HealthyActivity
    let title: String
    let subtitle: String
    let durationMinutes: Int

    var fullPrompt: String {
        "Try \(durationMinutes) min of \(activity.rawValue). \(subtitle)"
    }
}
