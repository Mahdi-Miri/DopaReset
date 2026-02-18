// DeviceActivityMonitorExtension.swift
// Extension target: ScreenTimeMonitorExtension
// The OS calls this when a DeviceActivityEvent threshold is exceeded.
// This file MUST live in a separate Extension target with entitlement:
//   com.apple.developer.family-controls
// and capability "Screen Time" enabled in Xcode.

import DeviceActivity
import UserNotifications
import Foundation

// MARK: - Extension Principal Class

@objc(DeviceActivityMonitorExtension)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // MARK: - Threshold exceeded

    /// Called by the OS when an event threshold is crossed.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // Derive monitored app ID from the event name
        let eventRawValue     = event.rawValue
        let prefix            = "DopaResetEvent_"
        let appIDString: String

        if eventRawValue.hasPrefix(prefix) {
            appIDString = String(eventRawValue.dropFirst(prefix.count))
        } else {
            appIDString = eventRawValue
        }

        // Read data from shared UserDefaults (app group)
        let defaults = UserDefaults(suiteName: "group.com.doparest.shared") ?? .standard

        // Load monitored apps
        guard
            let data = defaults.data(forKey: "monitoredApps"),
            let apps = try? JSONDecoder().decode([MonitoredAppProxy].self, from: data)
        else {
            sendGenericNotification(appName: "An app")
            return
        }

        // Find the matching app
        let matchedApp = apps.first { $0.id == appIDString }
        let appName    = matchedApp?.displayName ?? "An app"
        let minutes    = matchedApp?.thresholdMinutes ?? 30

        // Load user profile for activity suggestion
        let suggestion: String
        if let profileData = defaults.data(forKey: "userProfile"),
           let profile     = try? JSONDecoder().decode(UserProfileProxy.self, from: profileData) {
            suggestion = generateSuggestion(goal: profile.goal, activities: profile.favoriteActivities)
        } else {
            suggestion = "Try a 10-min walk or meditation."
        }

        // Record the event back to shared storage
        recordExceedEvent(appIDString: appIDString, appName: appName, defaults: defaults)

        // Fire the notification
        sendThresholdNotification(appName: appName, minutes: minutes, suggestion: suggestion)
    }

    // MARK: - Interval started / ended (optional overrides)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Nothing extra needed
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Nothing extra needed
    }

    // MARK: - Notification helpers

    private func sendThresholdNotification(appName: String, minutes: Int, suggestion: String) {
        let content            = UNMutableNotificationContent()
        content.title          = "You've been scrolling too long."
        content.body           = "\(appName) exceeded \(minutes) min. \(suggestion)"
        content.sound          = .default
        content.categoryIdentifier = "THRESHOLD_EXCEEDED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "exceed_\(appName)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendGenericNotification(appName: String) {
        sendThresholdNotification(
            appName: appName,
            minutes: 30,
            suggestion: "Take a healthy break. Try a short walk."
        )
    }

    // MARK: - Record exceed event to shared storage

    private func recordExceedEvent(appIDString: String, appName: String, defaults: UserDefaults) {
        var events = (try? JSONDecoder().decode(
            [ExceedEventProxy].self,
            from: defaults.data(forKey: "exceedEvents") ?? Data()
        )) ?? []

        let event = ExceedEventProxy(
            id: UUID().uuidString,
            monitoredAppID: appIDString,
            appDisplayName: appName,
            occurredAt: Date(),
            minutesOverThreshold: 0  // Extension doesn't know exact overage; main app can calculate
        )
        events.append(event)

        // Trim to 1000 events
        if events.count > 1000 { events = Array(events.suffix(1000)) }
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: "exceedEvents")
        }
    }

    // MARK: - Simple rule-based suggestion (no Foundation models available in extension)

    private func generateSuggestion(goal: String, activities: [String]) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeLabel = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"

        let suggestions: [String: String] = [
            "Improve Focus":    "Try 10 min of reading or journaling.",
            "Sleep Better":     "Do a short meditation before bed.",
            "Reduce Anxiety":   "Take a 5-min breathing walk outside.",
            "Quit Instagram":   "Draw something or listen to music."
        ]

        if let matched = suggestions[goal] {
            return matched
        }

        // Fall back to first favourite activity
        if let first = activities.first {
            return "Try \(first.lowercased()) for 10 minutes."
        }
        return "Take a healthy break and reset your \(timeLabel)."
    }
}

// MARK: - Lightweight proxy structs (mirror of main app models, Codable)
// These are duplicated here because the extension cannot import the main app module.

private struct MonitoredAppProxy: Codable {
    let id: String
    let bundleIdentifier: String
    let displayName: String
    let thresholdMinutes: Int
    let iconSystemName: String

    // Map from MonitoredApp (id is UUID)
    init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        self.id               = try container.decode(UUID.self, forKey: .id).uuidString
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.displayName      = try container.decode(String.self, forKey: .displayName)
        self.thresholdMinutes = try container.decode(Int.self,    forKey: .thresholdMinutes)
        self.iconSystemName   = try container.decode(String.self, forKey: .iconSystemName)
    }

    enum CodingKeys: String, CodingKey {
        case id, bundleIdentifier, displayName, thresholdMinutes, iconSystemName
    }
}

private struct UserProfileProxy: Codable {
    let goal: String
    let favoriteActivities: [String]

    init(from decoder: Decoder) throws {
        let container         = try decoder.container(keyedBy: CodingKeys.self)
        self.goal             = try container.decode(String.self,   forKey: .goal)
        self.favoriteActivities = try container.decode([String].self, forKey: .favoriteActivities)
    }

    enum CodingKeys: String, CodingKey {
        case goal, favoriteActivities
    }
}

private struct ExceedEventProxy: Codable {
    let id: String
    let monitoredAppID: String
    let appDisplayName: String
    let occurredAt: Date
    let minutesOverThreshold: Int
}
