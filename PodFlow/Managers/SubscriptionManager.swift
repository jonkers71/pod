import Foundation
import StoreKit
import SwiftUI

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: SubscriptionTier = .free
    @Published var snipsUsedThisMonth: Int = 0
    @Published var isPurchasing: Bool = false
    @Published var products: [Product] = []

    // Display pricing strings (shown in UI before StoreKit products load)
    let monthlyPrice: String  = "$4.99/month"
    let annualPrice: String   = "$39.99/year"
    let lifetimePrice: String = "$149.99"

    // Product IDs — must match exactly what you create in App Store Connect
    private let productIds = [
        "com.voltify.podflow.monthly_premium",
        "com.voltify.podflow.annual_premium",
        "com.voltify.podflow.lifetime_access"
    ]

    private var updates: Task<Void, Never>? = nil

    private init() {
        loadPersistedTier()

        // Listen for transactions that happen outside the app
        // (renewals, family sharing, Ask to Buy approvals, etc.)
        updates = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transaction: result)
            }
        }

        Task {
            await fetchProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updates?.cancel()
    }

    // MARK: - StoreKit 2 Product Fetching
    @MainActor
    func fetchProducts() async {
        do {
            self.products = try await Product.products(for: productIds)
        } catch {
            print("PodFlow: Failed to fetch StoreKit products: \(error)")
        }
    }

    // MARK: - Restore / Verify Existing Entitlements
    @MainActor
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            await handle(transaction: result)
        }
    }

    // MARK: - Transaction Handler
    private func handle(transaction result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await MainActor.run {
                if transaction.productID.contains("lifetime") {
                    self.currentTier = .lifetime
                } else if transaction.productID.contains("premium") {
                    self.currentTier = .premium
                }
                self.persistTier()
            }
            await transaction.finish()

        case .unverified(_, let error):
            print("PodFlow: Unverified transaction: \(error)")
        }
    }

    // MARK: - Purchase
    @MainActor
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            await handle(transaction: verification)
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Convenience Purchase Methods (called from PaywallView)
    func purchasePremiumMonthly() {
        Task {
            if let product = products.first(where: { $0.id.contains("monthly") }) {
                try? await purchase(product)
            }
        }
    }

    func purchasePremiumAnnual() {
        Task {
            if let product = products.first(where: { $0.id.contains("annual") }) {
                try? await purchase(product)
            }
        }
    }

    func purchaseLifetime() {
        Task {
            if let product = products.first(where: { $0.id.contains("lifetime") }) {
                try? await purchase(product)
            }
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await updateSubscriptionStatus()
            } catch {
                print("PodFlow: Restore purchases failed: \(error)")
            }
        }
    }

    // MARK: - Feature Gating
    func canUseAIFeature() -> Bool {
        if currentTier.hasUnlimitedAI { return true }
        return snipsUsedThisMonth < currentTier.maxSnipsPerMonth
    }

    // MARK: - Persistence
    private func persistTier() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "subscriptionTier")
        // Also sync to iCloud KV store so other devices pick it up
        NSUbiquitousKeyValueStore.default.set(currentTier.rawValue, forKey: "subscriptionTier")
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func loadPersistedTier() {
        // Check iCloud first, fall back to local UserDefaults
        let icloudTier = NSUbiquitousKeyValueStore.default.string(forKey: "subscriptionTier")
        let localTier  = UserDefaults.standard.string(forKey: "subscriptionTier")
        let tierString = icloudTier ?? localTier ?? SubscriptionTier.free.rawValue

        currentTier = SubscriptionTier(rawValue: tierString) ?? .free
    }
}
