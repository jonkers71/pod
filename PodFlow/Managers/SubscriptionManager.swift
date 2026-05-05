import Foundation
import StoreKit
import SwiftUI

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: SubscriptionTier = .free
    @Published var snipsUsedThisMonth: Int = 0
    @Published var isPurchasing: Bool = false
    @Published var products: [Product] = []

    // Product IDs from App Store Connect
    private let productIds = [
        "com.podflow.monthly_premium",
        "com.podflow.annual_premium",
        "com.podflow.lifetime_access"
    ]

    private var updates: Task<Void, Never>? = nil

    private init() {
        // Listen for transactions that happen outside the app
        updates = Task.detached {
            for await result in Transaction.updates {
                await self.handle(transaction: result)
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

    // MARK: - StoreKit 2 Fetching
    @MainActor
    func fetchProducts() async {
        do {
            self.products = try await Product.products(for: productIds)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    @MainActor
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            await handle(transaction: result)
        }
    }

    private func handle(transaction result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // Update UI based on productID
            await MainActor.run {
                if transaction.productID.contains("premium") {
                    self.currentTier = .premium
                } else if transaction.productID.contains("lifetime") {
                    self.currentTier = .lifetime
                }
                UserDefaults.standard.set(self.currentTier.rawValue, forKey: "subscriptionTier")
            }
            await transaction.finish()
        case .unverified(_, let error):
            print("Transaction unverified: \(error)")
        }
    }

    // MARK: - Purchase Actions
    @MainActor
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            await handle(transaction: verification)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // Legacy methods for UI compatibility
    func purchasePremiumMonthly() {
        Task {
            if let product = products.first(where: { $0.id == "com.podflow.monthly_premium" }) {
                try? await purchase(product)
            }
        }
    }

    func purchaseLifetime() {
        Task {
            if let product = products.first(where: { $0.id == "com.podflow.lifetime_access" }) {
                try? await purchase(product)
            }
        }
    }

    func restorePurchases() {
        Task {
            try? await AppStore.sync()
            await updateSubscriptionStatus()
        }
    }

    func canUseAIFeature() -> Bool {
        if currentTier.hasUnlimitedAI { return true }
        return snipsUsedThisMonth < currentTier.maxSnipsPerMonth
    }
}
