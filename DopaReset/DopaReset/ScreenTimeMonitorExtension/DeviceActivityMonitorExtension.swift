// DeviceActivityMonitorExtension.swift
// Extension target: ScreenTimeMonitorExtension
// The OS calls this when a DeviceActivityEvent threshold is exceeded.
// This file MUST live in a separate Extension target with entitlement:
//   com.apple.developer.family-controls
// and capability "Screen Time" enabled in Xcode.

//
//  DeviceActivityMonitorExtension.swift
//  ScreenTimeMonitorExtension (Extension target)
//

import DeviceActivity
import UserNotifications
import Foundation

@objc(DeviceActivityMonitorExtension)
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // If your compiler complains about init isolation, keep this.
    override nonisolated init() {
        super.init()
    }

    // MARK: - Threshold exceeded

    override nonisolated func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // Run your logic asynchronously (safe from a nonisolated override)
        Task { [event, activity] in
            await self.handleThreshold(event: event, activity: activity)
        }
    }

    // MARK: - Interval started / ended

    override nonisolated func intervalDidStart(for activity: DeviceActivityName) {
        Task { [activity] in
            await self.handleIntervalStart(activity)
        }
    }

    override nonisolated func intervalDidEnd(for activity: DeviceActivityName) {
        Task { [activity] in
            await self.handleIntervalEnd(activity)
        }
    }

    // MARK: - Async handlers

    private func handleThreshold(event: DeviceActivityEvent.Name, activity: DeviceActivityName) async {
        let eventRawValue = event.rawValue
        let prefix = "DopaResetEvent_"

        let appIDString: String = eventRawValue.hasPrefix(prefix)
            ? String(eventRawValue.dropFirst(prefix.count))
            : eventRawValue

        // ⚠️ MUST match your App Group ID in Signing & Capabilities
        let defaults = UserDefaults(suiteName: "group.com.doparest.shared") ?? .standard

        guard
            let data = defaults.data(forKey: "monitoredApps"),
            let apps = try? JSONDecoder().decode([MonitoredAppProxy].self, from: data)
        else {
            sendGenericNotification(appName: "An app")
            return
        }

        let matchedApp = apps.first { $0.id == appIDString }
        let appName = matchedApp?.displayName ?? "An app"
        let minutes = matchedApp?.thresholdMinutes ?? 30

        let suggestion: String
        if let profileData = defaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfileProxy.self, from: profileData) {
            suggestion = generateSuggestion(goal: profile.goal, activities: profile.favoriteActivities)
        } else {
            suggestion = "Try a 10-min walk or meditation."
        }

        recordExceedEvent(appIDString: appIDString, appName: appName, defaults: defaults)
        sendThresholdNotification(appName: appName, minutes: minutes, suggestion: suggestion)
    }

    private func handleIntervalStart(_ activity: DeviceActivityName) async {
        // optional
    }

    private func handleIntervalEnd(_ activity: DeviceActivityName) async {
        // optional
    }

    // MARK: - Notification helpers

    private func sendThresholdNotification(appName: String, minutes: Int, suggestion: String) {
        let content = UNMutableNotificationContent()
        content.title = "You've been scrolling too long."
        content.body = "\(appName) exceeded \(minutes) min. \(suggestion)"
        content.sound = .default
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

    // MARK: - Record exceed event

    private func recordExceedEvent(appIDString: String, appName: String, defaults: UserDefaults) {
        let existingData = defaults.data(forKey: "exceedEvents") ?? Data()
        var events = (try? JSONDecoder().decode([ExceedEventProxy].self, from: existingData)) ?? []

        let event = ExceedEventProxy(
            id: UUID().uuidString,
            monitoredAppID: appIDString,
            appDisplayName: appName,
            occurredAt: Date(),
            minutesOverThreshold: 0
        )

        events.append(event)

        if events.count > 1000 { events = Array(events.suffix(1000)) }

        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: "exceedEvents")
        }
    }

    // MARK: - Suggestion helper

    private func generateSuggestion(goal: String, activities: [String]) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeLabel = hour < 12 ? "morning" : hour < 17 ? "afternoon" : "evening"

        let suggestions: [String: String] = [
            "Improve Focus":  "Try 10 min of reading or journaling.",
            "Sleep Better":   "Do a short meditation before bed.",
            "Reduce Anxiety": "Take a 5-min breathing walk outside.",
            "Quit Instagram": "Draw something or listen to music."
        ]

        if let matched = suggestions[goal] { return matched }
        if let first = activities.first { return "Try \(first.lowercased()) for 10 minutes." }
        return "Take a healthy break and reset your \(timeLabel)."
    }
}

// MARK: - Proxy structs

private struct MonitoredAppProxy: Codable {
    let id: String
    let bundleIdentifier: String
    let displayName: String
    let thresholdMinutes: Int
    let iconSystemName: String
}

private struct UserProfileProxy: Codable {
    let goal: String
    let favoriteActivities: [String]
}

private struct ExceedEventProxy: Codable {
    let id: String
    let monitoredAppID: String
    let appDisplayName: String
    let occurredAt: Date
    let minutesOverThreshold: Int
}
