// AppConstants.swift
// Centralised constants for the DopaReset app

import Foundation

enum AppConstants {

    // MARK: - UserDefaults Keys
    enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userProfile            = "userProfile"
        static let monitoredApps          = "monitoredApps"
        static let exceedEvents           = "exceedEvents"
        static let isPremium              = "isPremium"
    }

    // MARK: - StoreKit
    enum StoreKit {
        static let monthlySubscriptionID = "com.doparest.premium.monthly"
        static let yearlySubscriptionID  = "com.doparest.premium.yearly"
    }

    // MARK: - Notification
    enum Notification {
        static let categoryID       = "THRESHOLD_EXCEEDED"
        static let actionOpenApp    = "OPEN_APP"
    }

    // MARK: - DeviceActivity
    enum DeviceActivity {
        static let scheduleName     = "DopaResetDailySchedule"
        static let eventNamePrefix  = "DopaResetEvent_"
    }

    // MARK: - Limits
    enum Limits {
        static let freeAppMonitorLimit: Int = 2
    }

    // MARK: - UI
    enum UI {
        static let cornerRadius: CGFloat = 28
        static let cardCornerRadius: CGFloat = 22
        static let shadowRadius: CGFloat = 12
    }
}
