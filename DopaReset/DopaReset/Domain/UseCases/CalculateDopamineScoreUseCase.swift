// CalculateDopamineScoreUseCase.swift
// Computes a 0–100 "dopamine control" score from exceed events

import Foundation

struct CalculateDopamineScoreUseCase {

    /// - Parameters:
    ///   - events: All threshold-exceed events in the period being scored.
    ///   - totalApps: Number of apps being monitored.
    ///   - days: Number of days in the period (default 7).
    /// - Returns: An integer score 0–100 where 100 = perfect control.
    func execute(events: [ThresholdExceedEvent], totalApps: Int, days: Int = 7) -> Int {
        guard totalApps > 0 else { return 100 }

        // Maximum expected events per day per app = 3
        let maxEvents = totalApps * days * 3
        let ratio     = Double(events.count) / Double(maxEvents)
        let raw       = max(0, 1.0 - ratio) * 100.0

        return Int(raw.rounded())
    }
}
