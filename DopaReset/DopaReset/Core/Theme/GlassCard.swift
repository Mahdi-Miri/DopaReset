// GlassCard.swift
// Reusable frosted-glass card component

import SwiftUI

/// A frosted glass card container used across all screens
struct GlassCard<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .shadow(color: Color.black.opacity(0.35), radius: AppConstants.UI.shadowRadius, x: 0, y: 6)
    }
}

// MARK: - Accent Card (coloured gradient border)

struct AccentGlassCard<Content: View>: View {

    let gradient: LinearGradient
    let content: Content

    init(gradient: LinearGradient = Color.dopaPurpleGradient,
         @ViewBuilder content: () -> Content) {
        self.gradient = gradient
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppConstants.UI.cardCornerRadius, style: .continuous)
                            .stroke(gradient, lineWidth: 1.5)
                    }
            }
            .shadow(color: Color.dopaPurple.opacity(0.25), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GlassBackground()

        VStack(spacing: 20) {
            GlassCard {
                Text("Regular Glass Card")
                    .foregroundStyle(.white)
                    .font(.headline)
            }

            AccentGlassCard {
                Text("Accent Glass Card")
                    .foregroundStyle(.white)
                    .font(.headline)
            }
        }
        .padding()
    }
}
