import SwiftUI

@main
struct PodFlowApp: App {
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var podcastService = PodcastIndexService.shared
    @StateObject private var spotifyService = SpotifyAuthService.shared
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioPlayerManager)
                .environmentObject(downloadManager)
                .environmentObject(podcastService)
                .environmentObject(spotifyService)
                .environmentObject(userSettings)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(userSettings.colorScheme)
                .onOpenURL { url in
                    // Handle Spotify OAuth callback
                    spotifyService.handleCallbackURL(url)
                }
        }
    }
}
