import Foundation
import Combine

class PodcastIndexService: ObservableObject {
    static let shared = PodcastIndexService()

    // ─────────────────────────────────────────────────────────────────────────
    // All requests now go through the Cloudflare Worker proxy.
    // The Podcast Index API key and secret live ONLY on Cloudflare's servers —
    // they are not present anywhere in this app binary.
    // Worker URL: https://podflow-proxy.bjonkers71.workers.dev
    // ─────────────────────────────────────────────────────────────────────────
    private let baseURL = "https://podflow-proxy.bjonkers71.workers.dev/api"

    @Published var trendingPodcasts: [Podcast] = []
    @Published var subscribedPodcasts: [Podcast] = []
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadSubscribedPodcasts()
    }

    // MARK: - Search Podcasts
    func searchPodcasts(query: String) async throws -> [Podcast] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&max=20") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        let decoded = try JSONDecoder().decode(PodcastIndexSearchResponse.self, from: data)
        return (decoded.feeds ?? []).map { mapFeedToPodcast($0) }
    }

    // MARK: - Fetch Trending Podcasts
    func fetchTrending(category: String? = nil) async throws -> [Podcast] {
        var urlString = "\(baseURL)/trending?max=20&lang=en"
        if let category = category {
            let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
            urlString += "&cat=\(encoded)"
        }
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PodcastIndexSearchResponse.self, from: data)
        return (decoded.feeds ?? []).map { mapFeedToPodcast($0) }
    }

    // MARK: - Fetch Episodes for a Podcast
    func fetchEpisodes(for podcast: Podcast, max: Int = 30) async throws -> [Episode] {
        guard let encodedURL = podcast.feedURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/episodes?url=\(encodedURL)&max=\(max)") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PodcastIndexEpisodesResponse.self, from: data)
        return (decoded.items ?? []).compactMap { mapEpisodeToModel($0, podcast: podcast) }
    }

    // MARK: - Fetch Episodes by Feed ID
    func fetchEpisodesByFeedId(_ feedId: Int, max: Int = 30) async throws -> [Episode] {
        guard let url = URL(string: "\(baseURL)/episodes/byid?id=\(feedId)&max=\(max)") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(PodcastIndexEpisodesResponse.self, from: data)
        return (decoded.items ?? []).compactMap { item in
            let placeholder = Podcast(
                id: "\(feedId)",
                title: item.feedTitle ?? "Unknown",
                author: "",
                description: "",
                imageURL: item.feedImage ?? "",
                feedURL: "",
                categories: [],
                episodeCount: 0
            )
            return mapEpisodeToModel(item, podcast: placeholder)
        }
    }

    // MARK: - Subscribe / Unsubscribe
    func subscribe(to podcast: Podcast) {
        var updated = podcast
        updated.isSubscribed = true
        if !subscribedPodcasts.contains(where: { $0.id == podcast.id }) {
            subscribedPodcasts.append(updated)
            saveSubscribedPodcasts()
        }
    }

    func unsubscribe(from podcast: Podcast) {
        subscribedPodcasts.removeAll { $0.id == podcast.id }
        saveSubscribedPodcasts()
    }

    func isSubscribed(to podcast: Podcast) -> Bool {
        subscribedPodcasts.contains(where: { $0.id == podcast.id })
    }

    // MARK: - Persistence
    private func saveSubscribedPodcasts() {
        if let data = try? JSONEncoder().encode(subscribedPodcasts) {
            UserDefaults.standard.set(data, forKey: "subscribedPodcasts")
        }
    }

    private func loadSubscribedPodcasts() {
        if let data = UserDefaults.standard.data(forKey: "subscribedPodcasts"),
           let podcasts = try? JSONDecoder().decode([Podcast].self, from: data) {
            subscribedPodcasts = podcasts
        }
    }

    // MARK: - Mapping
    private func mapFeedToPodcast(_ feed: PodcastIndexFeed) -> Podcast {
        Podcast(
            id: "\(feed.id)",
            title: feed.title,
            author: feed.author ?? feed.ownerName ?? "Unknown",
            description: feed.description ?? "",
            imageURL: feed.artwork ?? feed.image ?? "",
            feedURL: feed.url,
            categories: feed.categories.map { Array($0.values) } ?? [],
            episodeCount: feed.episodeCount ?? 0
        )
    }

    private func mapEpisodeToModel(_ item: PodcastIndexEpisode, podcast: Podcast) -> Episode? {
        guard let audioURL = item.enclosureUrl, !audioURL.isEmpty else { return nil }
        let publishDate = item.datePublished.map { Date(timeIntervalSince1970: $0) } ?? Date()
        return Episode(
            id: "\(item.id)",
            podcastId: podcast.id,
            podcastTitle: podcast.title,
            podcastImageURL: podcast.imageURL,
            title: item.title ?? "Untitled Episode",
            description: item.description ?? "",
            audioURL: audioURL,
            duration: TimeInterval(item.duration ?? 0),
            publishDate: publishDate,
            imageURL: item.image ?? item.feedImage ?? podcast.imageURL,
            episodeNumber: item.episode,
            season: item.season
        )
    }

    enum APIError: Error {
        case invalidURL
        case serverError
        case decodingError
    }
}
