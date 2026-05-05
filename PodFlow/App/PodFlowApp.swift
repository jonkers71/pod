import SwiftUI

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
        }
    }
}
