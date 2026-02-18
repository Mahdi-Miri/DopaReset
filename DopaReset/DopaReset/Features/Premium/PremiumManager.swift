// PremiumManager.swift
// StoreKit 2 subscription manager for the freemium model

import Foundation
import StoreKit
import Combine

@MainActor
final class PremiumManager: ObservableObject {

    // MARK: - Published

    @Published var isPremium: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseError: String?
    @Published var isLoading: Bool = false

    // MARK: - Private

    private var updateListenerTask: Task<Void, Error>?
    private let storage = LocalStorage.shared

    init() {
        isPremium = storage.isPremium
        updateListenerTask = listenForTransactionUpdates()
        Task { await loadProducts() }
        Task { await refreshPurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product IDs

    private var productIDs: [String] {
        [AppConstants.StoreKit.monthlySubscriptionID,
         AppConstants.StoreKit.yearlySubscriptionID]
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            purchaseError = "Could not load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePremiumStatus(transaction: transaction)
                await transaction.finish()
                isLoading = false
                return true
            case .userCancelled:
                isLoading = false
                return false
            case .pending:
                isLoading = false
                return false
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Status refresh

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await updatePremiumStatus(transaction: transaction)
            }
        }
    }

    private func updatePremiumStatus(transaction: Transaction) async {
        if productIDs.contains(transaction.productID) {
            let isActive = transaction.revocationDate == nil
                && (transaction.expirationDate == nil || transaction.expirationDate! > Date())
            isPremium = isActive
            storage.isPremium = isActive
        }
    }

    // MARK: - Transaction listener

    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.updatePremiumStatus(transaction: transaction)
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verification helper

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let item): return item
        }
    }

    // MARK: - Limit helpers

    func canAddApp(currentCount: Int) -> Bool {
        isPremium || currentCount < AppConstants.Limits.freeAppMonitorLimit
    }
}
