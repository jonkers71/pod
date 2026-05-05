import SwiftUI
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("colorSchemePreference") var colorSchemePreference: String = "system"
    @AppStorage("playbackSpeed") var playbackSpeed: Double = 1.0
    @AppStorage("trimSilence") var trimSilence: Bool = false
    @AppStorage("autoDownloadOnWifi") var autoDownloadOnWifi: Bool = true
    @AppStorage("skipForwardSeconds") var skipForwardSeconds: Int = 30
    @AppStorage("skipBackwardSeconds") var skipBackwardSeconds: Int = 15
    @AppStorage("sleepTimerMinutes") var sleepTimerMinutes: Int = 30
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("streamingQuality") var streamingQuality: String = "standard"
    @AppStorage("downloadQuality") var downloadQuality: String = "high"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""

    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private init() {}
}

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var currentTier: SubscriptionTier = .free
    @Published var snipsUsedThisMonth: Int = 0
    @Published var isPurchasing: Bool = false

    // Monthly and annual pricing
    let monthlyPrice: String = "$4.99/month"
    let annualPrice: String = "$39.99/year"
    let lifetimePrice: String = "$149.99"

    private init() {
        loadSubscriptionStatus()
    }

    private func loadSubscriptionStatus() {
        // In a real app, this would verify with StoreKit
        if let tierString = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: tierString) {
            currentTier = tier
        }
    }

    func canUseAIFeature() -> Bool {
        if currentTier.hasUnlimitedAI { return true }
        return snipsUsedThisMonth < currentTier.maxSnipsPerMonth
    }

    func purchasePremiumMonthly() {
        // StoreKit integration point
        isPurchasing = true
        // Simulate purchase for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentTier = .premium
            UserDefaults.standard.set(SubscriptionTier.premium.rawValue, forKey: "subscriptionTier")
            self.isPurchasing = false
        }
    }

    func purchaseLifetime() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.currentTier = .lifetime
            UserDefaults.standard.set(SubscriptionTier.lifetime.rawValue, forKey: "subscriptionTier")
            self.isPurchasing = false
        }
    }

    func restorePurchases() {
        // StoreKit restore purchases
    }
}
