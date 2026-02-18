// MonitoredApp.swift
// Domain model for an app the user wants to monitor

import Foundation

/// Represents one app being monitored with a per-app usage threshold
struct MonitoredApp: Codable, Identifiable, Equatable {

    let id: UUID

    /// Bundle token string – stored since FamilyActivityToken isn't directly Codable
    /// We store the bundle identifier as a proxy
    var bundleIdentifier: String

    /// Human-readable display name
    var displayName: String

    /// Time threshold in minutes
    var thresholdMinutes: Int

    /// SF Symbol name or custom icon name to display
    var iconSystemName: String

    init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        displayName: String,
        thresholdMinutes: Int = 30,
        iconSystemName: String = "app.fill"
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.thresholdMinutes = thresholdMinutes
        self.iconSystemName = iconSystemName
    }
}

// MARK: - ThresholdExceedEvent

/// A record that a threshold was exceeded at a specific point in time
struct ThresholdExceedEvent: Codable, Identifiable {
    let id: UUID
    let monitoredAppID: UUID
    let appDisplayName: String
    let occurredAt: Date
    let minutesOverThreshold: Int

    init(
        id: UUID = UUID(),
        monitoredAppID: UUID,
        appDisplayName: String,
        occurredAt: Date = Date(),
        minutesOverThreshold: Int
    ) {
        self.id = id
        self.monitoredAppID = monitoredAppID
        self.appDisplayName = appDisplayName
        self.occurredAt = occurredAt
        self.minutesOverThreshold = minutesOverThreshold
    }
}
