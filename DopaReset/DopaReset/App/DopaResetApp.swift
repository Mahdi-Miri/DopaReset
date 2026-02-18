// DopaResetApp.swift
// DopaReset – Smart Dopamine Detox
// App entry point – handles routing between onboarding and main tab view

import SwiftUI
import Combine 

@main
struct DopaResetApp: App {

    @StateObject private var userRepository = UserRepository()
    @StateObject private var premiumManager = PremiumManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userRepository)
                .environmentObject(premiumManager)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - RootView

/// Decides whether to show onboarding or the main dashboard
struct RootView: View {

    @EnvironmentObject var userRepository: UserRepository

    var body: some View {
        Group {
            if userRepository.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: userRepository.hasCompletedOnboarding)
    }
}

// MARK: - MainTabView

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "brain.head.profile")
                }
                .tag(0)

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.xaxis")
                }
                .tag(1)

            PremiumView()
                .tabItem {
                    Label("Premium", systemImage: "crown.fill")
                }
                .tag(2)
        }
        .tint(Color.dopaPurple)
    }
}
