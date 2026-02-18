// OnboardingViewModel.swift
// Drives the multi-step onboarding flow

import Foundation
import SwiftUI
import FamilyControls
import Combine 

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Step

    enum Step: Int, CaseIterable {
        case welcome       = 0
        case goal          = 1
        case activities    = 2
        case peakTime      = 3
        case appSelection  = 4
        case thresholds    = 5
        case screenTime    = 6
        case notifications = 7
        case done          = 8
    }

    // MARK: - Published

    @Published var currentStep: Step = .welcome
    @Published var selectedGoal: UserGoal = .focus
    @Published var selectedActivities: Set<HealthyActivity> = []
    @Published var selectedPeakTime: PeakScrollingTime = .evening
    @Published var activitySelection = FamilyActivitySelection()
    @Published var monitoredApps: [MonitoredApp] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let userRepository: UserRepository
    private let notificationManager = NotificationManager.shared

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    // MARK: - Navigation

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    func next() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = next
        }
    }

    func back() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentStep = prev
        }
    }

    // MARK: - Actions

    func toggleActivity(_ activity: HealthyActivity) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }

    func updateThreshold(for app: MonitoredApp, minutes: Int) {
        if let idx = monitoredApps.firstIndex(where: { $0.id == app.id }) {
            monitoredApps[idx].thresholdMinutes = minutes
        }
    }

    func buildMonitoredAppsFromSelection() {
        // For each token in the selection we create a MonitoredApp proxy
        // In a real app you'd resolve display names via the token's metadata
        let tokens = activitySelection.applicationTokens
        monitoredApps = tokens.enumerated().map { idx, _ in
            MonitoredApp(
                bundleIdentifier: "app.\(idx)",
                displayName: "App \(idx + 1)",
                thresholdMinutes: 30,
                iconSystemName: "app.fill"
            )
        }
    }

    // MARK: - Screen Time Authorization

    func requestScreenTimeAuthorization() async {
        isLoading = true
        let granted = await userRepository.requestScreenTimeAuthorization()
        isLoading = false
        if granted { next() } else {
            errorMessage = "Screen Time permission is required for monitoring. Please enable it in Settings."
        }
    }

    // MARK: - Notification Authorization

    func requestNotificationPermission() async {
        isLoading = true
        let granted = await notificationManager.requestPermission()
        notificationManager.registerCategories()
        isLoading = false
        if granted { completeOnboarding() } else {
            // Still complete; user can enable later
            completeOnboarding()
        }
    }

    // MARK: - Finish

    private func completeOnboarding() {
        let profile = UserProfile(
            goal: selectedGoal,
            favoriteActivities: Array(selectedActivities),
            peakScrollingTime: selectedPeakTime,
            onboardingCompletedAt: Date()
        )

        // Store the activitySelection in repository for monitoring
        userRepository.activitySelection = activitySelection
        userRepository.completeOnboarding(profile: profile, apps: monitoredApps)

        withAnimation { currentStep = .done }
    }
}
