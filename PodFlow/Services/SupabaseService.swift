import Foundation
import Combine

// MARK: - Supabase Service
// Handles user authentication and cloud sync for PodFlow.
//
// SETUP REQUIRED:
// 1. Add the Supabase Swift package in Xcode:
//    File → Add Package Dependencies → https://github.com/supabase/supabase-swift
// 2. Replace the placeholder URL and key below with your values from
//    https://app.supabase.com → Settings → API
// 3. See supabase/SETUP.md for full instructions
//
// Until Supabase is configured, the app works fully offline with local storage.
// Supabase sync is additive — it does not replace local storage, it mirrors it.

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    // Replace these with your Supabase project values
    private let supabaseURL = "https://mnxqwckssziljmraudax.supabase.co"
    private let supabaseKey = "sb_publishable_xvZB-p_WBQnTgOunrxUKaA_T_5R9Tv5"

    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String? = nil
    @Published var userEmail: String? = nil
    @Published var isSyncing: Bool = false

    var isConfigured: Bool {
        return supabaseURL != "YOUR_SUPABASE_URL" && supabaseKey != "YOUR_SUPABASE_ANON_KEY"
    }

    private init() {
        loadLocalSession()
    }

    // MARK: - Auth

    /// Sign in with Apple — call this from the Profile screen
    func signInWithApple(identityToken: String, fullName: String?) async {
        guard isConfigured else {
            print("SupabaseService: Not configured. See supabase/SETUP.md")
            return
        }
        // Full implementation requires the Supabase Swift package.
        // Once the package is added, replace this with:
        //
        // let session = try await supabase.auth.signInWithIdToken(
        //     credentials: .init(provider: .apple, idToken: identityToken)
        // )
        // await MainActor.run {
        //     self.isAuthenticated = true
        //     self.currentUserId = session.user.id.uuidString
        //     self.userEmail = session.user.email
        // }
        print("SupabaseService: signInWithApple called — add Supabase package to activate")
    }

    func signOut() async {
        isAuthenticated = false
        currentUserId = nil
        userEmail = nil
        UserDefaults.standard.removeObject(forKey: "supabaseUserId")
    }

    // MARK: - Sync Subscriptions
    func syncSubscriptions(_ podcasts: [Podcast]) async {
        guard isConfigured, isAuthenticated, let userId = currentUserId else { return }
        isSyncing = true
        defer { Task { @MainActor in self.isSyncing = false } }

        // Once Supabase package is added, replace with:
        // try await supabase
        //     .from("podcast_subscriptions")
        //     .upsert(podcasts.map { SupabasePodcastSubscription(from: $0, userId: userId) })
        //     .execute()
        print("SupabaseService: syncSubscriptions — \(podcasts.count) podcasts (add Supabase package to activate)")
    }

    func fetchSubscriptions() async -> [Podcast] {
        guard isConfigured, isAuthenticated else { return [] }
        // Once Supabase package is added, replace with:
        // let response = try await supabase
        //     .from("podcast_subscriptions")
        //     .select()
        //     .eq("user_id", value: currentUserId!)
        //     .execute()
        // return response.value as [SupabasePodcastSubscription] mapped to [Podcast]
        return []
    }

    // MARK: - Sync Snips
    func syncSnip(_ snip: Snip) async {
        guard isConfigured, isAuthenticated, let userId = currentUserId else { return }
        // Once Supabase package is added:
        // try await supabase.from("snips").upsert(SupabaseSnip(from: snip, userId: userId)).execute()
        print("SupabaseService: syncSnip '\(snip.episodeTitle)' (add Supabase package to activate)")
    }

    func fetchSnips() async -> [Snip] {
        guard isConfigured, isAuthenticated else { return [] }
        return []
    }

    // MARK: - Sync Playback Position
    func syncPlaybackPosition(episodeId: String, podcastId: String, position: TimeInterval, duration: TimeInterval) async {
        guard isConfigured, isAuthenticated, let userId = currentUserId else { return }
        // Once Supabase package is added:
        // try await supabase.from("playback_positions")
        //     .upsert(["user_id": userId, "episode_id": episodeId, "position": position, ...])
        //     .execute()
        _ = userId // suppress unused warning
    }

    func fetchPlaybackPosition(episodeId: String) async -> TimeInterval? {
        guard isConfigured, isAuthenticated else { return nil }
        return nil
    }

    // MARK: - Record Listening History (for future personalisation)
    func recordListeningEvent(episodeId: String, podcastId: String, podcastTitle: String,
                               categories: [String], percentPlayed: Double, completed: Bool) async {
        guard isConfigured, isAuthenticated else { return }
        // Once Supabase package is added, insert into listening_history table
    }

    // MARK: - Local Session Persistence
    private func loadLocalSession() {
        if let userId = UserDefaults.standard.string(forKey: "supabaseUserId") {
            currentUserId = userId
            isAuthenticated = true
        }
    }
}

// MARK: - Supabase Data Transfer Objects
// These will be used once the Supabase package is added

struct SupabasePodcastSubscription: Codable {
    let userId: String
    let podcastId: String
    let podcastTitle: String
    let podcastAuthor: String?
    let podcastImage: String?
    let feedUrl: String
    let categories: [String]

    init(from podcast: Podcast, userId: String) {
        self.userId = userId
        self.podcastId = podcast.id
        self.podcastTitle = podcast.title
        self.podcastAuthor = podcast.author
        self.podcastImage = podcast.imageURL
        self.feedUrl = podcast.feedURL
        self.categories = podcast.categories
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case podcastId = "podcast_id"
        case podcastTitle = "podcast_title"
        case podcastAuthor = "podcast_author"
        case podcastImage = "podcast_image"
        case feedUrl = "feed_url"
        case categories
    }
}

struct SupabaseSnip: Codable {
    let userId: String
    let episodeId: String
    let episodeTitle: String
    let podcastTitle: String
    let podcastImage: String?
    let startTime: Double
    let endTime: Double
    let transcriptText: String?
    let summary: String?
    let note: String

    init(from snip: Snip, userId: String) {
        self.userId = userId
        self.episodeId = snip.episodeId
        self.episodeTitle = snip.episodeTitle
        self.podcastTitle = snip.podcastTitle
        self.podcastImage = snip.podcastImageURL
        self.startTime = snip.startTime
        self.endTime = snip.endTime
        self.transcriptText = snip.text.isEmpty ? nil : snip.text
        self.summary = snip.summary.isEmpty ? nil : snip.summary
        self.note = snip.note
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case episodeId = "episode_id"
        case episodeTitle = "episode_title"
        case podcastTitle = "podcast_title"
        case podcastImage = "podcast_image"
        case startTime = "start_time"
        case endTime = "end_time"
        case transcriptText = "transcript_text"
        case summary, note
    }
}
