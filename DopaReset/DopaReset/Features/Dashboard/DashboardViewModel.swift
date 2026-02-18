// DashboardViewModel.swift
// Drives the Dashboard screen

import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published

    @Published var monitoredApps: [MonitoredApp] = []
    @Published var todayEvents: [ThresholdExceedEvent] = []
    @Published var activitySuggestion: ActivitySuggestion?
    @Published var dopamineScore: Int = 100
    @Published var streakDays: Int = 0

    // MARK: - Dependencies

    private let userRepository: UserRepository
    private let suggestionUseCase = GenerateActivitySuggestionUseCase()
    private let scoreUseCase = CalculateDopamineScoreUseCase()
    private var cancellables = Set<AnyCancellable>()

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        bind()
    }

    // MARK: - Binding

    private func bind() {
        userRepository.$monitoredApps
            .receive(on: RunLoop.main)
            .assign(to: &$monitoredApps)

        userRepository.$exceedEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] events in
                guard let self else { return }
                let today = Date().startOfDay
                let tomorrow = Date().endOfDay
                self.todayEvents = events.filter {
                    $0.occurredAt >= today && $0.occurredAt <= tomorrow
                }
                self.dopamineScore = self.scoreUseCase.execute(
                    events: self.todayEvents,
                    totalApps: max(self.monitoredApps.count, 1),
                    days: 1
                )
                self.streakDays = self.calculateStreak(from: events)
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func load() {
        userRepository.refreshEvents()

        let profile = userRepository.userProfile
        activitySuggestion = suggestionUseCase.execute(
            goal: profile?.goal ?? .focus,
            favoriteActivities: profile?.favoriteActivities ?? []
        )
    }

    // MARK: - Streak

    private func calculateStreak(from events: [ThresholdExceedEvent]) -> Int {
        var streak = 0
        var checkDate = Date().addingTimeInterval(-24 * 60 * 60) // yesterday
        while true {
            let dayStart = checkDate.startOfDay
            let dayEnd   = checkDate.endOfDay
            let hadExceed = events.contains { $0.occurredAt >= dayStart && $0.occurredAt <= dayEnd }
            if hadExceed { break }
            streak += 1
            checkDate = checkDate.addingTimeInterval(-24 * 60 * 60)
            if streak > 365 { break }
        }
        return streak
    }

    // MARK: - Quick test notification

    /// Simulates a threshold exceed – useful during development
    func simulateExceed(for app: MonitoredApp) {
        let event = ThresholdExceedEvent(
            monitoredAppID: app.id,
            appDisplayName: app.displayName,
            minutesOverThreshold: Int.random(in: 1...15)
        )
        userRepository.recordExceedEvent(event)

        let suggestion = activitySuggestion?.fullPrompt ?? "Take a healthy break."
        NotificationManager.shared.scheduleThresholdNotification(
            appName: app.displayName,
            minutes: app.thresholdMinutes,
            suggestion: suggestion
        )
    }
}
