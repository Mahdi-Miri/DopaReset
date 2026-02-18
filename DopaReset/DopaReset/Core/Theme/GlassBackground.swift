// GlassBackground.swift
// Full-screen gradient background with subtle noise texture

import SwiftUI

/// Full-screen background used on every major screen
struct GlassBackground: View {

    var body: some View {
        ZStack {
            // Base deep navy gradient
            Color.dopaGradient
                .ignoresSafeArea()

            // Subtle purple glow orb top-right
            Circle()
                .fill(Color.dopaPurple.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 120, y: -200)

            // Subtle lavender glow orb bottom-left
            Circle()
                .fill(Color.dopaLavender.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -100, y: 350)
        }
    }
}

// MARK: - Preview

#Preview {
    GlassBackground()
}
