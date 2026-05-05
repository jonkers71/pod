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

    var body: some Scene {
        WindowGroup {
            OnboardingGate()
                .environmentObject(audioPlayerManager)
                .environmentObject(downloadManager)
                .environmentObject(podcastService)
                .environmentObject(spotifyService)
                .environmentObject(userSettings)
                .environmentObject(subscriptionManager)
                // Apply the semantic background colour at root so every screen inherits it
                .background(Color.appBackground.ignoresSafeArea())
                .preferredColorScheme(userSettings.colorScheme)
                .onOpenURL { url in
                    spotifyService.handleCallbackURL(url)
                }
                // Tint all system controls (toggles, pickers, etc.) with the logo teal
                .tint(Color.accentTeal)
                .onAppear {
                    requestNotificationPermissions()
                    setupICloudSync()
                }
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    private func setupICloudSync() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { _ in
            // Handle cross-device sync here
            let tier = NSUbiquitousKeyValueStore.default.string(forKey: "subscriptionTier")
            if let tier = tier {
                UserDefaults.standard.set(tier, forKey: "subscriptionTier")
            }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
