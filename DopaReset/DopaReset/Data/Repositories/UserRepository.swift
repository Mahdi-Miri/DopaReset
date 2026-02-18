// UserRepository.swift
// Observable repository – single source of truth consumed by ViewModels

import Foundation
import Combine
import FamilyControls
import DeviceActivity

@MainActor
final class UserRepository: ObservableObject {

    // MARK: - Published state

    @Published var hasCompletedOnboarding: Bool
    @Published var userProfile: UserProfile?
    @Published var monitoredApps: [MonitoredApp]
    @Published var exceedEvents: [ThresholdExceedEvent]
    @Published var screenTimeAuthorized: Bool = false

    // Raw FamilyActivitySelection from picker (not persisted directly)
    @Published var activitySelection = FamilyActivitySelection()

    // MARK: - Private

    private let storage = LocalStorage.shared
    private let deviceActivityCenter = DeviceActivityCenter()

    init() {
        self.hasCompletedOnboarding = storage.hasCompletedOnboarding
        self.userProfile            = storage.userProfile
        self.monitoredApps          = storage.monitoredApps
        self.exceedEvents           = storage.exceedEvents
    }

    // MARK: - Onboarding

    func completeOnboarding(profile: UserProfile, apps: [MonitoredApp]) {
        storage.userProfile            = profile
        storage.monitoredApps          = apps
        storage.hasCompletedOnboarding = true

        self.userProfile            = profile
        self.monitoredApps          = apps
        self.hasCompletedOnboarding = true

        Task { await startMonitoring() }
    }

    // MARK: - Screen Time Authorization

    func requestScreenTimeAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            screenTimeAuthorized = true
            return true
        } catch {
            print("[UserRepository] Screen Time authorization failed: \(error)")
            return false
        }
    }

    // MARK: - Monitoring

    /// Starts DeviceActivity monitoring for all monitored apps
    func startMonitoring() async {
        guard !monitoredApps.isEmpty else { return }

        // Build a single schedule covering the whole day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats:       true
        )

        // Create one DeviceActivityEvent per app
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for app in monitoredApps {
            let eventName = DeviceActivityEvent.Name(
                rawValue: "\(AppConstants.DeviceActivity.eventNamePrefix)\(app.id.uuidString)"
            )
            let threshold = DateComponents(minute: app.thresholdMinutes)

            // Build a FamilyActivitySelection containing this app's token
            // The token must have been obtained from FamilyActivityPicker during onboarding
            // Here we use the selection stored from onboarding
            var sel = activitySelection
            // For the actual monitoring we pass the full selection;
            // production apps would store per-app tokens separately.
            let event = DeviceActivityEvent(
                applications: sel.applicationTokens,
                threshold:    threshold
            )
            events[eventName] = event
        }

        let activityName = DeviceActivityName(
            rawValue: AppConstants.DeviceActivity.scheduleName
        )

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: events)
            print("[UserRepository] Monitoring started for \(monitoredApps.count) app(s)")
        } catch {
            print("[UserRepository] Failed to start monitoring: \(error)")
        }
    }

    func stopMonitoring() {
        let activityName = DeviceActivityName(rawValue: AppConstants.DeviceActivity.scheduleName)
        deviceActivityCenter.stopMonitoring([activityName])
    }

    // MARK: - Apps

    func updateMonitoredApps(_ apps: [MonitoredApp]) {
        storage.monitoredApps = apps
        monitoredApps = apps
        Task { await startMonitoring() }
    }

    // MARK: - Events

    func recordExceedEvent(_ event: ThresholdExceedEvent) {
        storage.appendExceedEvent(event)
        exceedEvents = storage.exceedEvents
    }

    func refreshEvents() {
        exceedEvents = storage.exceedEvents
    }

    // MARK: - Reset (for testing)

    func resetAll() {
        storage.hasCompletedOnboarding = false
        storage.userProfile            = nil
        storage.monitoredApps          = []
        storage.exceedEvents           = []
        hasCompletedOnboarding = false
        userProfile            = nil
        monitoredApps          = []
        exceedEvents           = []
        stopMonitoring()
    }
}
