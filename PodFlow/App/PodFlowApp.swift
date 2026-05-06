import SwiftUI
import UserNotifications

@main
struct PodFlowApp: App {
    @StateObject private var audioPlayerManager  = AudioPlayerManager.shared
    @StateObject private var downloadManager     = DownloadManager.shared
    @StateObject private var podcastService      = PodcastIndexService.shared
    @StateObject private var spotifyService      = SpotifyAuthService.shared
    @StateObject private var userSettings        = UserSettings.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var snipStore           = SnipStore.shared

    var body: some Scene {
        WindowGroup {
            OnboardingGate()
                .environmentObject(audioPlayerManager)
                .environmentObject(downloadManager)
                .environmentObject(podcastService)
                .environmentObject(spotifyService)
                .environmentObject(userSettings)
                .environmentObject(subscriptionManager)
                .environmentObject(snipStore)
                .background(Color.appBackground.ignoresSafeArea())
                .preferredColorScheme(userSettings.colorScheme)
                .onOpenURL { url in
                    spotifyService.handleCallbackURL(url)
                }
                .tint(Color.accentTeal)
                .onAppear {
                    requestNotificationPermissions()
                    setupICloudSync()
                }
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
    }

    private func setupICloudSync() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            if let tier = NSUbiquitousKeyValueStore.default.string(forKey: "subscriptionTier") {
                UserDefaults.standard.set(tier, forKey: "subscriptionTier")
            }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
