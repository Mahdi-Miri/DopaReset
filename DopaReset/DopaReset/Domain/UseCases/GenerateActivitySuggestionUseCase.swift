// GenerateActivitySuggestionUseCase.swift
// Deterministic rule-based engine for healthy activity suggestions
// Inputs: time of day, user goal, favourite activities

import Foundation

struct GenerateActivitySuggestionUseCase {

    // MARK: - Lookup tables

    private let goalPriority: [UserGoal: [HealthyActivity]] = [
        .focus:         [.reading, .journaling, .meditation, .walking],
        .sleep:         [.meditation, .stretching, .journaling, .reading],
        .reduceAnxiety: [.meditation, .walking, .stretching, .coldShower],
        .quitInstagram: [.reading, .drawing, .music, .cooking]
    ]

    private let timePriority: [Date.TimeOfDay: [HealthyActivity]] = [
        .morning:   [.meditation, .exercise, .coldShower, .walking],
        .afternoon: [.walking, .stretching, .reading, .music],
        .evening:   [.reading, .cooking, .journaling, .drawing],
        .night:     [.meditation, .stretching, .journaling, .reading]
    ]

    private let subtitles: [HealthyActivity: String] = [
        .reading:    "Give your eyes a rest from the screen.",
        .meditation: "Breathe deeply and reset your nervous system.",
        .walking:    "Move your body and shift your environment.",
        .journaling: "Write down how you're feeling right now.",
        .exercise:   "Get a natural dopamine boost through movement.",
        .cooking:    "Engage your senses with something nourishing.",
        .drawing:    "Let your creativity flow without a scroll feed.",
        .music:      "Put on headphones and be fully present.",
        .stretching: "Release tension held in your body.",
        .coldShower: "A quick reset that rewires your reward circuit."
    ]

    private let durations: [HealthyActivity: Int] = [
        .reading:    20, .meditation: 10, .walking: 15, .journaling: 10,
        .exercise:   20, .cooking:    25, .drawing: 15, .music:       15,
        .stretching: 10, .coldShower:  3
    ]

    // MARK: - Execute

    /// Returns the best activity suggestion given current context.
    func execute(
        goal: UserGoal,
        favoriteActivities: [HealthyActivity],
        at date: Date = Date()
    ) -> ActivitySuggestion {

        let timeOfDay = date.timeOfDay

        // Score each candidate activity
        var scores: [HealthyActivity: Int] = [:]

        let goalList = goalPriority[goal] ?? []
        let timeList = timePriority[timeOfDay] ?? []

        // Sum scores: goal match + time match + favourite bonus
        for activity in HealthyActivity.allCases {
            var score = 0
            if let idx = goalList.firstIndex(of: activity) { score += (goalList.count - idx) * 3 }
            if let idx = timeList.firstIndex(of: activity) { score += (timeList.count - idx) * 2 }
            if favoriteActivities.contains(activity)       { score += 5 }
            scores[activity] = score
        }

        // Pick the highest scoring activity
        let best = scores.max(by: { $0.value < $1.value })?.key ?? .meditation

        return ActivitySuggestion(
            activity: best,
            title: "\(best.emoji) Try \(best.rawValue)",
            subtitle: subtitles[best] ?? "Take a healthy break.",
            durationMinutes: durations[best] ?? 10
        )
    }
}
