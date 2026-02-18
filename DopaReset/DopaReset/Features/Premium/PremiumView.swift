// PremiumView.swift
// Premium subscription paywall screen

import SwiftUI
import StoreKit

struct PremiumView: View {

    @EnvironmentObject var premiumManager: PremiumManager
    @State private var selectedProductIndex: Int = 1 // default to yearly

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 28) {
                        heroSection
                        benefitsList
                        productsSection
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dopaPurpleGradient)
                    .frame(width: 90, height: 90)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            if premiumManager.isPremium {
                Text("You're Premium 🌟")
                    .font(.title2).bold()
                    .foregroundStyle(.white)

                Text("Thank you for supporting DopaReset. All features are unlocked.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Text("Upgrade to Premium")
                    .font(.title2).bold()
                    .foregroundStyle(.white)

                Text("Unlock unlimited apps, advanced analytics, and smart activity suggestions.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("What you get")
                    .font(.headline).foregroundStyle(.white)

                ForEach(PremiumBenefit.all) { benefit in
                    BenefitRow(benefit: benefit)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Products

    @ViewBuilder
    private var productsSection: some View {
        if premiumManager.isPremium {
            GlassCard {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.dopaMint)
                        .font(.title2)
                    Text("Active Subscription").font(.headline).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
        } else if premiumManager.isLoading && premiumManager.products.isEmpty {
            ProgressView().tint(.white)
        } else if premiumManager.products.isEmpty {
            GlassCard {
                VStack(spacing: 8) {
                    Text("Products unavailable")
                        .foregroundStyle(.white.opacity(0.7))
                    Button("Retry") {
                        Task { await premiumManager.loadProducts() }
                    }
                    .foregroundStyle(Color.dopaPurple)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            VStack(spacing: 12) {
                ForEach(premiumManager.products.indices, id: \.self) { idx in
                    let product = premiumManager.products[idx]
                    ProductCard(
                        product: product,
                        isSelected: selectedProductIndex == idx,
                        isBestValue: idx == 1 && premiumManager.products.count > 1
                    ) { selectedProductIndex = idx }
                }

                PrimaryButton(
                    title: premiumManager.isLoading ? "Processing…" : subscribeButtonTitle,
                    isEnabled: !premiumManager.isLoading && !premiumManager.products.isEmpty
                ) {
                    guard premiumManager.products.indices.contains(selectedProductIndex) else { return }
                    Task {
                        await premiumManager.purchase(premiumManager.products[selectedProductIndex])
                    }
                }

                if let error = premiumManager.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.dopaCoral)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var subscribeButtonTitle: String {
        guard premiumManager.products.indices.contains(selectedProductIndex) else {
            return "Subscribe"
        }
        let product = premiumManager.products[selectedProductIndex]
        return "Subscribe · \(product.displayPrice)"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await premiumManager.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.6))

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage in App Store settings.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Supporting types

private struct PremiumBenefit: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    static let all: [PremiumBenefit] = [
        .init(icon: "infinity",            title: "Unlimited Apps",     subtitle: "Monitor as many apps as you want",         color: .dopaPurple),
        .init(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", subtitle: "Deep weekly & monthly insights",  color: .dopaLavender),
        .init(icon: "brain",               title: "Smart Activity Engine", subtitle: "Context-aware personalised suggestions", color: .dopaMint),
        .init(icon: "bell.badge.waveform", title: "Custom Notifications", subtitle: "Personalise your alert messages",        color: .dopaCoral),
    ]
}

private struct BenefitRow: View {
    let benefit: PremiumBenefit
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: benefit.icon)
                .foregroundStyle(benefit.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title).font(.subheadline).bold().foregroundStyle(.white)
                Text(benefit.subtitle).font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName).font(.headline).foregroundStyle(.white)
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2).bold()
                                .foregroundStyle(Color.dopaNavy)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.dopaMint))
                        }
                    }
                    if let sub = product.subscription {
                        Text(sub.subscriptionPeriod.localizedDescription)
                            .font(.caption).foregroundStyle(.white.opacity(0.6))
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline).bold()
                    .foregroundStyle(.white)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.dopaPurple : Color.white.opacity(0.4))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.dopaPurple.opacity(0.25) : Color.white.opacity(0.07))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Color.dopaPurple : Color.white.opacity(0.12), lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - SubscriptionPeriod description

private extension Product.SubscriptionPeriod {
    var localizedDescription: String {
        switch unit {
        case .day:   return value == 7 ? "Weekly" : "\(value) day(s)"
        case .week:  return "\(value) week(s)"
        case .month: return value == 1 ? "Monthly" : "\(value) months"
        case .year:  return "Yearly"
        @unknown default: return "Subscription"
        }
    }
}

// MARK: - Preview

#Preview {
    PremiumView()
        .environmentObject(PremiumManager())
        .environmentObject(UserRepository())
}
