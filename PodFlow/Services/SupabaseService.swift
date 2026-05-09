import Foundation
import Supabase
import Combine

// MARK: - Supabase Service
// Full integration — requires the Supabase Swift package (already added).
// Project: https://mnxqwckssziljmraudax.supabase.co

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    // Supabase client — initialised with project URL and anon key
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://mnxqwckssziljmraudax.supabase.co")!,
        supabaseKey: "sb_publishable_xvZB-p_WBQnTgOunrxUKaA_T_5R9Tv5"
    )

    @Published var isAuthenticated: Bool = false
    @Published var currentUserId: String? = nil
    @Published var userEmail: String? = nil
    @Published var isSyncing: Bool = false

    private init() {
        Task { await restoreSession() }
    }

    // MARK: - Session Restore
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserId = session.user.id.uuidString
                self.userEmail = session.user.email
            }
        } catch {
            // No active session — user needs to sign in
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        await MainActor.run {
            self.isAuthenticated = true
            self.currentUserId = session.user.id.uuidString
            self.userEmail = session.user.email
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        if let session = response.session {
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUserId = session.user.id.uuidString
                self.userEmail = session.user.email
            }
        }
        // If no session, email confirmation is required — user will see a message
    }

    // MARK: - Sign Out
    func signOut() async {
        try? await client.auth.signOut()
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUserId = nil
            self.userEmail = nil
        }
    }

    // MARK: - Sync Subscriptions to Cloud
    func syncSubscriptions(_ podcasts: [Podcast]) async {
        guard isAuthenticated, let userId = currentUserId else { return }
        await MainActor.run { isSyncing = true }
        defer { Task { @MainActor in self.isSyncing = false } }

        do {
            let rows = podcasts.map { podcast in
                SupabasePodcastSubscription(from: podcast, userId: userId)
            }
            try await client
                .from("podcast_subscriptions")
                .upsert(rows, onConflict: "user_id,podcast_id")
                .execute()
        } catch {
            print("SupabaseService: syncSubscriptions error: \(error)")
        }
    }

    // MARK: - Fetch Subscriptions from Cloud
    func fetchSubscriptions() async -> [Podcast] {
        guard isAuthenticated, let userId = currentUserId else { return [] }
        do {
            let rows: [SupabasePodcastSubscription] = try await client
                .from("podcast_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            return rows.map { $0.toPodcast() }
        } catch {
            print("SupabaseService: fetchSubscriptions error: \(error)")
            return []
        }
    }

    // MARK: - Remove Subscription from Cloud
    func removeSubscription(podcastId: String) async {
        guard isAuthenticated, let userId = currentUserId else { return }
        do {
            try await client
                .from("podcast_subscriptions")
                .delete()
                .eq("user_id", value: userId)
                .eq("podcast_id", value: podcastId)
                .execute()
        } catch {
            print("SupabaseService: removeSubscription error: \(error)")
        }
    }

    // MARK: - Sync Snip to Cloud
    func syncSnip(_ snip: Snip) async {
        guard isAuthenticated, let userId = currentUserId else { return }
        do {
            let row = SupabaseSnip(from: snip, userId: userId)
            try await client
                .from("snips")
                .upsert(row, onConflict: "id")
                .execute()
        } catch {
            print("SupabaseService: syncSnip error: \(error)")
        }
    }

    // MARK: - Fetch Snips from Cloud
    func fetchSnips() async -> [Snip] {
        guard isAuthenticated, let userId = currentUserId else { return [] }
        do {
            let rows: [SupabaseSnip] = try await client
                .from("snips")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return rows.map { $0.toSnip() }
        } catch {
            print("SupabaseService: fetchSnips error: \(error)")
            return []
        }
    }

    // MARK: - Sync Playback Position
    func syncPlaybackPosition(episodeId: String, podcastId: String,
                               position: TimeInterval, duration: TimeInterval) async {
        guard isAuthenticated, let userId = currentUserId else { return }
        do {
            let row: [String: AnyJSON] = [
                "user_id": .string(userId),
                "episode_id": .string(episodeId),
                "podcast_id": .string(podcastId),
                "position": .double(position),
                "duration": .double(duration),
                "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await client
                .from("playback_positions")
                .upsert(row, onConflict: "user_id,episode_id")
                .execute()
        } catch {
            print("SupabaseService: syncPlaybackPosition error: \(error)")
        }
    }

    // MARK: - Record Listening Event (for future personalisation)
    func recordListeningEvent(episodeId: String, podcastId: String,
                               podcastTitle: String, categories: [String],
                               percentPlayed: Double, completed: Bool) async {
        guard isAuthenticated, let userId = currentUserId else { return }
        do {
            let row: [String: AnyJSON] = [
                "user_id": .string(userId),
                "episode_id": .string(episodeId),
                "podcast_id": .string(podcastId),
                "podcast_title": .string(podcastTitle),
                "percent_played": .double(percentPlayed),
                "was_completed": .bool(completed),
                "listened_at": .string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await client
                .from("listening_history")
                .insert(row)
                .execute()
        } catch {
            print("SupabaseService: recordListeningEvent error: \(error)")
        }
    }
}

// MARK: - Supabase Data Transfer Objects

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

    func toPodcast() -> Podcast {
        Podcast(
            id: podcastId,
            title: podcastTitle,
            author: podcastAuthor ?? "",
            description: "",
            imageURL: podcastImage ?? "",
            feedURL: feedUrl,
            categories: categories,
            episodeCount: 0,
            isSubscribed: true
        )
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
    let id: String
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
    let createdAt: String?

    init(from snip: Snip, userId: String) {
        self.id = snip.id
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
        self.createdAt = ISO8601DateFormatter().string(from: snip.createdAt)
    }

    func toSnip() -> Snip {
        let date = createdAt.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        return Snip(
            id: id,
            episodeId: episodeId,
            episodeTitle: episodeTitle,
            podcastTitle: podcastTitle,
            podcastImageURL: podcastImage ?? "",
            startTime: startTime,
            endTime: endTime,
            text: transcriptText ?? "",
            summary: summary ?? "",
            createdAt: date,
            note: note
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case episodeId = "episode_id"
        case episodeTitle = "episode_title"
        case podcastTitle = "podcast_title"
        case podcastImage = "podcast_image"
        case startTime = "start_time"
        case endTime = "end_time"
        case transcriptText = "transcript_text"
        case summary, note
        case createdAt = "created_at"
    }
}
