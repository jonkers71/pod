import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var spotifyService: SpotifyAuthService
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showPaywall: Bool = false
    @State private var showAppearancePicker: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // Subscription Banner
                subscriptionSection

                // Spotify
                spotifySection

                // Playback Settings
                playbackSection

                // Storage
                storageSection

                // Appearance
                appearanceSection

                // About
                aboutSection
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden).background(Color.appBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Subscription
    private var subscriptionSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: tierIcon)
                        .font(.title2)
                        .foregroundColor(tierColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionManager.currentTier.displayName + " Plan")
                        .font(.headline)
                    Text(tierDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if subscriptionManager.currentTier == .free {
                    Button("Upgrade") { showPaywall = true }
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color.accentTeal)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)

            if subscriptionManager.currentTier == .free {
                HStack {
                    Image(systemName: "scissors").foregroundColor(Color.accentOrange)
                    Text("Snips used this month")
                    Spacer()
                    Text("\(subscriptionManager.snipsUsedThisMonth) / \(subscriptionManager.currentTier.maxSnipsPerMonth)")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var tierColor: Color {
        switch subscriptionManager.currentTier {
        case .free: return .gray
        case .premium: return Color.accentTeal
        case .lifetime: return Color.accentPurple
        }
    }

    private var tierIcon: String {
        switch subscriptionManager.currentTier {
        case .free: return "person.circle"
        case .premium: return "star.fill"
        case .lifetime: return "crown.fill"
        }
    }

    private var tierDescription: String {
        switch subscriptionManager.currentTier {
        case .free: return "Basic listening with ads · 5 snips/month"
        case .premium: return "Ad-free · Unlimited AI · Cloud sync"
        case .lifetime: return "All features forever · Thank you! 🙏"
        }
    }

    // MARK: - Spotify
    private var spotifySection: some View {
        Section("Spotify") {
            if spotifyService.isAuthenticated {
                HStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.green)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected to Spotify")
                            .font(.subheadline).fontWeight(.medium)
                        if let user = spotifyService.spotifyUser {
                            Text(user.displayName ?? user.email ?? "Spotify User")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Disconnect") {
                        spotifyService.disconnect()
                    }
                    .font(.caption).foregroundColor(.red)
                }
            } else {
                SpotifyConnectButton()
            }
        }
    }

    // MARK: - Playback
    private var playbackSection: some View {
        Section("Playback") {
            HStack {
                Label("Default Speed", systemImage: "speedometer")
                Spacer()
                Picker("", selection: $userSettings.playbackSpeed) {
                    ForEach([0.75, 1.0, 1.25, 1.5, 1.75, 2.0], id: \.self) { speed in
                        Text("\(String(format: "%.2g", speed))×").tag(speed)
                    }
                }
                .pickerStyle(.menu)
            }

            Toggle(isOn: $userSettings.trimSilence) {
                Label("Trim Silence", systemImage: "waveform.path.ecg")
            }
            .tint(Color.accentTeal)

            Toggle(isOn: $userSettings.autoDownloadOnWifi) {
                Label("Auto-Download on Wi-Fi", systemImage: "wifi")
            }
            .tint(Color.accentTeal)

            HStack {
                Label("Skip Forward", systemImage: "goforward")
                Spacer()
                Picker("", selection: $userSettings.skipForwardSeconds) {
                    ForEach([10, 15, 30, 45, 60], id: \.self) { s in Text("\(s)s").tag(s) }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Label("Skip Backward", systemImage: "gobackward")
                Spacer()
                Picker("", selection: $userSettings.skipBackwardSeconds) {
                    ForEach([5, 10, 15, 30], id: \.self) { s in Text("\(s)s").tag(s) }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Storage
    private var storageSection: some View {
        Section("Storage") {
            HStack {
                Label("Downloaded Episodes", systemImage: "arrow.down.circle.fill")
                Spacer()
                Text(downloadManager.totalDownloadedSize)
                    .foregroundColor(.secondary)
            }
            Button(role: .destructive) {
                for id in downloadManager.downloadedEpisodeIds {
                    downloadManager.deleteDownload(episodeId: id)
                }
            } label: {
                Label("Delete All Downloads", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Appearance
    private var appearanceSection: some View {
        Section("Appearance") {
            HStack {
                Label("Theme", systemImage: "circle.lefthalf.filled")
                Spacer()
                Picker("", selection: $userSettings.colorSchemePreference) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0 (1)").foregroundColor(.secondary)
            }
            Link(destination: URL(string: "https://podflow.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: "https://podflow.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            Button {
                subscriptionManager.restorePurchases()
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Spotify Connect Button
struct SpotifyConnectButton: View {
    @EnvironmentObject var spotifyService: SpotifyAuthService

    var body: some View {
        Button {
            // Trigger OAuth — needs a UIWindowScene for presentation context
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                let context = SpotifyPresentationContext(viewController: root)
                spotifyService.authenticate(presentationContext: context)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .foregroundColor(.green)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Spotify")
                        .font(.subheadline).fontWeight(.medium)
                    Text("Access your Spotify saved shows")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary).font(.caption)
            }
        }
        .foregroundColor(.primary)
    }
}
