// UserProfile.swift
// Domain model representing a DopaReset user

import Foundation

// MARK: - User Goal

enum UserGoal: String, CaseIterable, Codable, Identifiable {
    case focus         = "Improve Focus"
    case sleep         = "Sleep Better"
    case reduceAnxiety = "Reduce Anxiety"
    case quitInstagram = "Quit Instagram"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .focus:         return "🧠"
        case .sleep:         return "😴"
        case .reduceAnxiety: return "🧘"
        case .quitInstagram: return "📵"
        }
    }

    var description: String {
        switch self {
        case .focus:         return "Build deeper concentration and flow states."
        case .sleep:         return "Reclaim your evenings and sleep schedule."
        case .reduceAnxiety: return "Calm your nervous system from constant pings."
        case .quitInstagram: return "Break the Instagram scroll habit for good."
        }
    }
}

// MARK: - Healthy Activity

enum HealthyActivity: String, CaseIterable, Codable, Identifiable {
    case reading      = "Reading"
    case meditation   = "Meditation"
    case walking      = "Walking"
    case journaling   = "Journaling"
    case exercise     = "Exercise"
    case cooking      = "Cooking"
    case drawing      = "Drawing"
    case music        = "Music"
    case stretching   = "Stretching"
    case coldShower   = "Cold Shower"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .reading:    return "📚"
        case .meditation: return "🧘"
        case .walking:    return "🚶"
        case .journaling: return "✍️"
        case .exercise:   return "💪"
        case .cooking:    return "🍳"
        case .drawing:    return "🎨"
        case .music:      return "🎵"
        case .stretching: return "🤸"
        case .coldShower: return "🚿"
        }
    }
}

// MARK: - Peak Scrolling Time

enum PeakScrollingTime: String, CaseIterable, Codable, Identifiable {
    case morning   = "Morning (7–10am)"
    case lunch     = "Lunch (12–2pm)"
    case afternoon = "Afternoon (3–6pm)"
    case evening   = "Evening (7–10pm)"
    case lateNight = "Late Night (10pm+)"

    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .morning:   return "☀️"
        case .lunch:     return "🌤"
        case .afternoon: return "⛅️"
        case .evening:   return "🌆"
        case .lateNight: return "🌙"
        }
    }
}

// MARK: - UserProfile

struct UserProfile: Codable, Equatable {
    var goal: UserGoal
    var favoriteActivities: [HealthyActivity]
    var peakScrollingTime: PeakScrollingTime
    var onboardingCompletedAt: Date

    init(
        goal: UserGoal = .focus,
        favoriteActivities: [HealthyActivity] = [],
        peakScrollingTime: PeakScrollingTime = .evening,
        onboardingCompletedAt: Date = Date()
    ) {
        self.goal = goal
        self.favoriteActivities = favoriteActivities
        self.peakScrollingTime = peakScrollingTime
        self.onboardingCompletedAt = onboardingCompletedAt
    }
}
