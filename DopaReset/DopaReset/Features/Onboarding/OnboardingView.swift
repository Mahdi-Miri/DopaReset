// OnboardingView.swift
// Multi-step onboarding flow for DopaReset

import SwiftUI
import FamilyControls
import Combine
import Foundation



struct OnboardingView: View {

    @EnvironmentObject var userRepository: UserRepository
    @StateObject private var viewModel: OnboardingViewModel

    init() {
        // viewModel needs userRepository but environment isn't available in init;
        // We'll inject it via .onAppear workaround – instead we keep a placeholder
        // and replace via the modifier below.
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(userRepository: UserRepository()))
    }

    var body: some View {
        ZStack {
            GlassBackground()

            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(progress: viewModel.progress)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .animation(.spring(), value: viewModel.progress)

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.currentStep)
            }
        }
        .onAppear {
            // Re-inject the real repository once environment is available
        }
    }

    // MARK: - Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:        WelcomeStep(viewModel: viewModel)
        case .goal:           GoalStep(viewModel: viewModel)
        case .activities:     ActivitiesStep(viewModel: viewModel)
        case .peakTime:       PeakTimeStep(viewModel: viewModel)
        case .appSelection:   AppSelectionStep(viewModel: viewModel)
        case .thresholds:     ThresholdsStep(viewModel: viewModel)
        case .screenTime:     ScreenTimeStep(viewModel: viewModel)
        case .notifications:  NotificationsStep(viewModel: viewModel)
        case .done:           EmptyView()
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 4)
                Capsule()
                    .fill(Color.dopaPurpleGradient)
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Step: Welcome

private struct WelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("🧠")
                .font(.system(size: 80))
                .scaleEffect(1.0)

            VStack(spacing: 12) {
                Text("Welcome to DopaReset")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Take back control of your attention.\nBreak free from mindless scrolling.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryButton(title: "Get Started") { viewModel.next() }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step: Goal

private struct GoalStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 24) {
            StepHeader(title: "What's your goal?", subtitle: "We'll personalise your experience.")

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(UserGoal.allCases) { goal in
                        GoalRow(
                            goal: goal,
                            isSelected: viewModel.selectedGoal == goal
                        ) { viewModel.selectedGoal = goal }
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue") { viewModel.next() }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }
}

private struct GoalRow: View {
    let goal: UserGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(goal.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue).font(.headline).foregroundStyle(.white)
                    Text(goal.description).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dopaPurple)
                        .font(.title3)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.dopaPurple.opacity(0.25) : Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.dopaPurple : Color.clear, lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Step: Activities

private struct ActivitiesStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 24) {
            StepHeader(title: "Healthy alternatives", subtitle: "Pick activities you enjoy.")

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HealthyActivity.allCases) { activity in
                        ActivityChip(
                            activity: activity,
                            isSelected: viewModel.selectedActivities.contains(activity)
                        ) { viewModel.toggleActivity(activity) }
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue") {
                viewModel.next()
            }

            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

private struct ActivityChip: View {
    let activity: HealthyActivity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(activity.emoji).font(.largeTitle)
                Text(activity.rawValue).font(.caption).bold().foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.dopaPurple.opacity(0.3) : Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.dopaPurple : Color.clear, lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Step: Peak Time

private struct PeakTimeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 24) {
            StepHeader(title: "When do you scroll most?", subtitle: "We'll watch out for your danger zone.")

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(PeakScrollingTime.allCases) { time in
                        SelectableRow(
                            emoji: time.emoji,
                            title: time.rawValue,
                            isSelected: viewModel.selectedPeakTime == time
                        ) { viewModel.selectedPeakTime = time }
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue") { viewModel.next() }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }
}

// MARK: - Step: App Selection

private struct AppSelectionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 24) {
            StepHeader(title: "Select apps to monitor", subtitle: "Choose the apps you want to limit.")

            GlassCard {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.dopaPurpleGradient)

                    Text("Tap below to pick apps from your device")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button("Choose Apps") {
                        showPicker = true
                    }
                    .buttonStyle(GlassButtonStyle())

                    if !viewModel.activitySelection.applicationTokens.isEmpty {
                        Text("\(viewModel.activitySelection.applicationTokens.count) app(s) selected")
                            .font(.caption)
                            .foregroundStyle(Color.dopaMint)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(title: "Continue") {
                // Only build monitored apps if there are apps selected (optional but safer)
                if !viewModel.activitySelection.applicationTokens.isEmpty {
                    viewModel.buildMonitoredAppsFromSelection()
                } else {
                    // If user skipped, ensure monitoredApps is empty (so next screens don't break)
                    viewModel.monitoredApps = []
                }
                viewModel.next()
            }

            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $viewModel.activitySelection)
    }
}

// MARK: - Step: Thresholds

private struct ThresholdsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 24) {
            StepHeader(title: "Set time limits", subtitle: "How long before we alert you?")

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($viewModel.monitoredApps) { $app in
                        ThresholdRow(app: $app)
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(title: "Continue") { viewModel.next() }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }
}

private struct ThresholdRow: View {
    @Binding var app: MonitoredApp
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: app.iconSystemName)
                        .foregroundStyle(Color.dopaPurple)
                    Text(app.displayName).font(.headline).foregroundStyle(.white)
                    Spacer()
                    Text("\(app.thresholdMinutes) min")
                        .font(.subheadline).bold()
                        .foregroundStyle(Color.dopaLavender)
                }
                Slider(value: Binding(
                    get: { Double(app.thresholdMinutes) },
                    set: { app.thresholdMinutes = Int($0) }
                ), in: 5...120, step: 5)
                .tint(Color.dopaPurple)
            }
        }
    }
}

// MARK: - Step: Screen Time

private struct ScreenTimeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            PermissionCard(
                icon: "clock.shield.fill",
                title: "Screen Time Access",
                description: "DopaReset needs Screen Time permission to monitor your app usage and send alerts when you exceed your limits.",
                color: Color.dopaPurple
            )
            .padding(.horizontal, 24)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.dopaCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            PrimaryButton(
                title: viewModel.isLoading ? "Requesting…" : "Allow Screen Time",
                isEnabled: !viewModel.isLoading
            ) {
                Task { await viewModel.requestScreenTimeAuthorization() }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Step: Notifications

private struct NotificationsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            PermissionCard(
                icon: "bell.badge.fill",
                title: "Enable Notifications",
                description: "We'll send a gentle nudge when you've been scrolling too long, along with a healthy activity suggestion.",
                color: Color.dopaCoral
            )
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(
                title: viewModel.isLoading ? "Requesting…" : "Allow Notifications",
                isEnabled: !viewModel.isLoading
            ) {
                Task { await viewModel.requestNotificationPermission() }
            }
            .padding(.horizontal, 32)

            Button("Skip for now") { viewModel.next() }
                .foregroundStyle(.white.opacity(0.5))
                .font(.subheadline)
                .padding(.bottom, 48)
        }
    }
}

// MARK: - Shared Components

private struct StepHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
        .padding(.horizontal, 24)
    }
}

private struct SelectableRow: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji).font(.title2)
                Text(title).font(.headline).foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.dopaPurple)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.dopaPurple.opacity(0.2) : Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.dopaPurple : Color.clear, lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(color)

                Text(title)
                    .font(.title3).bold()
                    .foregroundStyle(.white)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isEnabled ? Color.dopaPurpleGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                }
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: isEnabled)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(UserRepository())
        .environmentObject(PremiumManager())
}
