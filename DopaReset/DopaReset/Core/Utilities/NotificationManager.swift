// NotificationManager.swift
// Manages local notification requests and permissions

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var permissionGranted: Bool = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await checkPermissionStatus() }
    }

    // MARK: - Permission

    /// Requests authorisation to post alerts, sounds, and badges
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            return granted
        } catch {
            print("[NotificationManager] Permission request failed: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Posts a notification that the user has exceeded their threshold for a given app.
    /// - Parameters:
    ///   - appName:       The display name of the app that exceeded the threshold.
    ///   - minutes:       The threshold in minutes.
    ///   - suggestion:    A healthy activity suggestion to include in the body.
    func scheduleThresholdNotification(
        appName: String,
        minutes: Int,
        suggestion: String
    ) {
        let content            = UNMutableNotificationContent()
        content.title          = "You've been scrolling too long."
        content.body           = "\(appName) exceeded \(minutes) min. \(suggestion)"
        content.sound          = .default
        content.categoryIdentifier = AppConstants.Notification.categoryID

        // Deliver immediately (called from extension or background task)
        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request  = UNNotificationRequest(
            identifier: "threshold_\(appName)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error { print("[NotificationManager] Failed to add notification: \(error)") }
        }
    }

    // MARK: - Category registration

    /// Registers notification categories so the system knows about our actions
    func registerCategories() {
        let openAction = UNNotificationAction(
            identifier: AppConstants.Notification.actionOpenApp,
            title: "Open DopaReset",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: AppConstants.Notification.categoryID,
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Clear

    func clearAllDelivered() {
        center.removeAllDeliveredNotifications()
    }
}
