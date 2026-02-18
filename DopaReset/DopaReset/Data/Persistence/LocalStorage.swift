// LocalStorage.swift
// High-level local storage façade used by repositories

import Foundation

final class LocalStorage {

    static let shared = LocalStorage()
    private let manager = UserDefaultsManager.shared
    private init() {}

    // MARK: - User Profile

    var userProfile: UserProfile? {
        get { manager.get(UserProfile.self, forKey: AppConstants.Keys.userProfile) }
        set {
            if let val = newValue { manager.set(val, forKey: AppConstants.Keys.userProfile) }
            else { manager.remove(forKey: AppConstants.Keys.userProfile) }
        }
    }

    // MARK: - Onboarding

    var hasCompletedOnboarding: Bool {
        get { manager.getBool(forKey: AppConstants.Keys.hasCompletedOnboarding) }
        set { manager.setBool(newValue, forKey: AppConstants.Keys.hasCompletedOnboarding) }
    }

    // MARK: - Monitored Apps

    var monitoredApps: [MonitoredApp] {
        get { manager.get([MonitoredApp].self, forKey: AppConstants.Keys.monitoredApps) ?? [] }
        set { manager.set(newValue, forKey: AppConstants.Keys.monitoredApps) }
    }

    // MARK: - Exceed Events

    var exceedEvents: [ThresholdExceedEvent] {
        get { manager.get([ThresholdExceedEvent].self, forKey: AppConstants.Keys.exceedEvents) ?? [] }
        set { manager.set(newValue, forKey: AppConstants.Keys.exceedEvents) }
    }

    func appendExceedEvent(_ event: ThresholdExceedEvent) {
        var current = exceedEvents
        current.append(event)
        // Keep only last 90 days to avoid unbounded growth
        let cutoff  = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        current     = current.filter { $0.occurredAt > cutoff }
        exceedEvents = current
    }

    // MARK: - Premium

    var isPremium: Bool {
        get { manager.getBool(forKey: AppConstants.Keys.isPremium) }
        set { manager.setBool(newValue, forKey: AppConstants.Keys.isPremium) }
    }
}
