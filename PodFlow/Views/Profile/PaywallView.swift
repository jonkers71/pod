import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: PlanOption = .annual

    enum PlanOption { case monthly, annual, lifetime }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero
                    heroSection
                        .padding(.bottom, 24)

                    // Features list
                    featuresSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    // Plan picker
                    planPickerSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    // CTA Button
                    ctaButton
                        .padding(.horizontal, 24)

                    // Restore + legal
                    legalSection
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color("AccentBlue"), Color("AccentPurple")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 280)

            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.9))
                Text("PodFlow Premium")
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                Text("Unlock the full listening experience")
                    .font(.subheadline).foregroundColor(.white.opacity(0.85))
            }
        }
    }

    // MARK: - Features
    private var featuresSection: some View {
        VStack(spacing: 14) {
            ForEach(premiumFeatures, id: \.title) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundColor(feature.color)
                        .frame(width: 36, height: 36)
                        .background(feature.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title).font(.subheadline).fontWeight(.semibold)
                        Text(feature.description).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plan Picker
    private var planPickerSection: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach([PlanOption.monthly, .annual, .lifetime], id: \.self) { plan in
                PlanOptionCard(plan: plan, isSelected: selectedPlan == plan) {
                    withAnimation(.spring(response: 0.3)) { selectedPlan = plan }
                }
            }
        }
    }

    // MARK: - CTA
    private var ctaButton: some View {
        Button {
            switch selectedPlan {
            case .monthly, .annual: subscriptionManager.purchasePremiumMonthly()
            case .lifetime: subscriptionManager.purchaseLifetime()
            }
            dismiss()
        } label: {
            Group {
                if subscriptionManager.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(ctaLabel)
                        .font(.headline).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).padding()
            .background(
                LinearGradient(colors: [Color("AccentBlue"), Color("AccentPurple")],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color("AccentBlue").opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .disabled(subscriptionManager.isPurchasing)
    }

    private var ctaLabel: String {
        switch selectedPlan {
        case .monthly: return "Start Free Trial · \(subscriptionManager.monthlyPrice)"
        case .annual:  return "Start Free Trial · \(subscriptionManager.annualPrice)"
        case .lifetime: return "Get Lifetime Access · \(subscriptionManager.lifetimePrice)"
        }
    }

    // MARK: - Legal
    private var legalSection: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") { subscriptionManager.restorePurchases() }
                .font(.caption).foregroundColor(Color("AccentBlue"))
            Text("Payment will be charged to your Apple ID account. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Data
    private var premiumFeatures: [(title: String, description: String, icon: String, color: Color)] {
        [
            ("Ad-Free Listening", "No banner ads, ever", "nosign", Color("AccentBlue")),
            ("Unlimited AI Transcripts", "Full searchable transcripts for every episode", "text.alignleft", Color("AccentPurple")),
            ("Unlimited Snips", "Save as many clips as you want", "scissors", Color("AccentOrange")),
            ("AI Episode Summaries", "Know what's in an episode before you listen", "sparkles", Color("AccentBlue")),
            ("Export to Notion & Obsidian", "Sync your insights to your favourite apps", "arrow.up.right.square", .green),
            ("Cloud Backup & Sync", "Your library synced across all your devices", "icloud", Color("AccentBlue")),
        ]
    }
}

// MARK: - Plan Option Card
struct PlanOptionCard: View {
    let plan: PaywallView.PlanOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planTitle)
                            .font(.subheadline).fontWeight(.semibold)
                        if plan == .annual {
                            Text("BEST VALUE")
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        if plan == .lifetime {
                            Text("LIMITED")
                                .font(.caption2).fontWeight(.bold)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color("AccentOrange"))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(planSubtitle)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(planPrice)
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(isSelected ? Color("AccentBlue") : .primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color("AccentBlue") : Color(.systemGray4))
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected ? Color("AccentBlue").opacity(0.08) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("AccentBlue") : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundColor(.primary)
    }

    private var planTitle: String {
        switch plan {
        case .monthly:  return "Monthly"
        case .annual:   return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    private var planSubtitle: String {
        switch plan {
        case .monthly:  return "Billed monthly · Cancel anytime"
        case .annual:   return "Billed yearly · Save 33%"
        case .lifetime: return "One-time payment · All future updates"
        }
    }

    private var planPrice: String {
        switch plan {
        case .monthly:  return "$4.99/mo"
        case .annual:   return "$39.99/yr"
        case .lifetime: return "$149.99"
        }
    }
}

// MARK: - Ad Banner View
struct AdBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "megaphone.fill")
                .foregroundColor(.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Advertisement")
                    .font(.caption2).foregroundColor(.secondary).textCase(.uppercase)
                Text("Upgrade to Premium to remove ads")
                    .font(.caption).foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: "xmark")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
