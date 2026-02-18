// Color+Extensions.swift
// Custom brand colours for DopaReset

import SwiftUI

extension Color {

    /// Primary purple brand colour
    static let dopaPurple   = Color(red: 0.54, green: 0.33, blue: 0.95)

    /// Soft lavender accent
    static let dopaLavender = Color(red: 0.72, green: 0.60, blue: 0.98)

    /// Warm coral accent for alerts
    static let dopaCoral    = Color(red: 0.98, green: 0.45, blue: 0.45)

    /// Mint green for positive states
    static let dopaMint     = Color(red: 0.35, green: 0.92, blue: 0.75)

    /// Deep navy for backgrounds
    static let dopaNavy     = Color(red: 0.06, green: 0.05, blue: 0.14)

    /// Card surface colour
    static let dopaCard     = Color(red: 0.10, green: 0.08, blue: 0.22)

    // MARK: - Gradient helpers

    static var dopaGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.06, blue: 0.22),
                Color(red: 0.04, green: 0.03, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dopaPurpleGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dopaPurple, Color.dopaLavender],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var dopaSuccessGradient: LinearGradient {
        LinearGradient(
            colors: [Color.dopaMint, Color(red: 0.20, green: 0.75, blue: 0.60)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
