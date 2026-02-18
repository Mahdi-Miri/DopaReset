// DashboardView.swift
// Main dashboard screen showing today's status and monitored apps

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var userRepository: UserRepository
    @StateObject private var viewModel: DashboardViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(userRepository: UserRepository()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        scoreCard
                        suggestionCard
                        monitoredAppsSection
                        todayEventsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("DopaReset")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                // Inject real repository
                viewModel.load()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting())
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                Text("Stay Present")
                    .font(.title2).bold()
                    .foregroundStyle(.white)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.dopaPurple.opacity(0.25))
                    .frame(width: 52, height: 52)
                Text(userRepository.userProfile?.goal.emoji ?? "🧠")
                    .font(.title2)
            }
        }
    }

    // MARK: - Dopamine Score Card

    private var scoreCard: some View {
        AccentGlassCard {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dopamine Score")
                        .font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .kerning(1)

                    Text("\(viewModel.dopamineScore)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(scoreColor)

                    Text(scoreLabel)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                VStack(spacing: 12) {
                    StatPill(icon: "flame.fill", value: "\(viewModel.streakDays)d", color: .orange)
                    StatPill(icon: "bell.slash.fill", value: "\(viewModel.todayEvents.count)", color: .dopaCoral)
                }
            }
        }
    }

    private var scoreColor: Color {
        switch viewModel.dopamineScore {
        case 80...100: return .dopaMint
        case 60...79:  return .dopaLavender
        case 40...59:  return .yellow
        default:       return .dopaCoral
        }
    }

    private var scoreLabel: String {
        switch viewModel.dopamineScore {
        case 80...100: return "Great control today 🌟"
        case 60...79:  return "Good progress 👍"
        case 40...59:  return "Could be better 🤔"
        default:       return "Time to reset 🚨"
        }
    }

    // MARK: - Suggestion Card

    @ViewBuilder
    private var suggestionCard: some View {
        if let suggestion = viewModel.activitySuggestion {
            GlassCard {
                HStack(spacing: 16) {
                    Text(suggestion.activity.emoji)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Try This Now")
                            .font(.caption).bold()
                            .foregroundStyle(Color.dopaMint)
                            .textCase(.uppercase)
                            .kerning(1)

                        Text(suggestion.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("\(suggestion.durationMinutes) min · \(suggestion.subtitle)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Monitored Apps

    private var monitoredAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Monitored Apps", icon: "eye.fill")

            if viewModel.monitoredApps.isEmpty {
                GlassCard {
                    Text("No apps monitored yet.\nComplete onboarding to add apps.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(viewModel.monitoredApps) { app in
                    MonitoredAppRow(app: app) {
                        viewModel.simulateExceed(for: app)
                    }
                }
            }
        }
    }

    // MARK: - Today Events

    private var todayEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Alerts", icon: "bell.badge.fill")

            if viewModel.todayEvents.isEmpty {
                GlassCard {
                    HStack {
                        Text("🎉")
                        Text("No threshold exceeded today!")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(viewModel.todayEvents.prefix(5)) { event in
                    EventRow(event: event)
                }
            }
        }
    }

    // MARK: - Helpers

    private func greeting() -> String {
        switch Date().timeOfDay {
        case .morning:   return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening:   return "Good evening"
        case .night:     return "Late night?"
        }
    }
}

// MARK: - Sub-components

private struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.caption)
            Text(value).foregroundStyle(.white).font(.caption).bold()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.1)))
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.white)
    }
}

private struct MonitoredAppRow: View {
    let app: MonitoredApp
    let onTest: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: app.iconSystemName)
                    .foregroundStyle(Color.dopaPurple)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.dopaPurple.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.displayName).font(.headline).foregroundStyle(.white)
                    Text("Limit: \(app.thresholdMinutes) min/day")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Button("Test") { onTest() }
                    .font(.caption).bold()
                    .foregroundStyle(Color.dopaLavender)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.dopaPurple.opacity(0.2)))
            }
        }
    }
}

private struct EventRow: View {
    let event: ThresholdExceedEvent
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.dopaCoral)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.appDisplayName).font(.subheadline).bold().foregroundStyle(.white)
                    Text(event.occurredAt.formatted(as: "h:mm a"))
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text("+\(event.minutesOverThreshold) min")
                    .font(.caption).bold()
                    .foregroundStyle(Color.dopaCoral)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(UserRepository())
        .environmentObject(PremiumManager())
}
