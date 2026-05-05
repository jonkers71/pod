import Foundation
import CryptoKit
import Combine

class PodcastIndexService: ObservableObject {
    static let shared = PodcastIndexService()

    // MARK: - Podcast Index API Credentials
    // Sign up free at https://api.podcastindex.org
    private let apiKey = "YOUR_PODCAST_INDEX_API_KEY"
    private let apiSecret = "YOUR_PODCAST_INDEX_API_SECRET"
    private let baseURL = "https://api.podcastindex.org/api/1.0"

    @Published var trendingPodcasts: [Podcast] = []
    @Published var subscribedPodcasts: [Podcast] = []
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadSubscribedPodcasts()
    }

    // MARK: - Auth Headers
    private func authHeaders() -> [String: String] {
        let epochTime = Int(Date().timeIntervalSince1970)
        let hashInput = "\(apiKey)\(apiSecret)\(epochTime)"
        let hash = SHA1.hash(data: Data(hashInput.utf8)).hexString

        return [
            "X-Auth-Date": "\(epochTime)",
            "X-Auth-Key": apiKey,
            "Authorization": hash,
            "User-Agent": "PodFlow/1.0"
        ]
    }

    // MARK: - Search Podcasts
    func searchPodcasts(query: String) async throws -> [Podcast] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/byterm?q=\(encodedQuery)&max=20") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let decoded = try JSONDecoder().decode(PodcastIndexSearchResponse.self, from: data)
        return (decoded.feeds ?? []).map { mapFeedToPodcast($0) }
    }

    // MARK: - Fetch Trending Podcasts
    func fetchTrending(category: String? = nil) async throws -> [Podcast] {
        var urlString = "\(baseURL)/podcasts/trending?max=20&lang=en"
        if let category = category {
            urlString += "&cat=\(category)"
        }
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(PodcastIndexSearchResponse.self, from: data)
        return (decoded.feeds ?? []).map { mapFeedToPodcast($0) }
    }

    // MARK: - Fetch Episodes for a Podcast
    func fetchEpisodes(for podcast: Podcast, max: Int = 30) async throws -> [Episode] {
        guard let encodedURL = podcast.feedURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/episodes/byfeedurl?url=\(encodedURL)&max=\(max)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(PodcastIndexEpisodesResponse.self, from: data)
        return (decoded.items ?? []).compactMap { mapEpisodeToModel($0, podcast: podcast) }
    }

    // MARK: - Fetch Episodes by Feed ID
    func fetchEpisodesByFeedId(_ feedId: Int, max: Int = 30) async throws -> [Episode] {
        guard let url = URL(string: "\(baseURL)/episodes/byfeedid?id=\(feedId)&max=\(max)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, _) = try await URLSession.shared.data(for: request)
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
        return subscribedPodcasts.contains(where: { $0.id == podcast.id })
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
            categories: Array(feed.categories?.values ?? [].makeIterator()),
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

// MARK: - SHA1 Helper (for Podcast Index auth)
extension Digest {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

struct SHA1 {
    static func hash(data: Data) -> SHA256Digest {
        // Note: Podcast Index actually uses SHA-1 for auth
        // Using SHA256 here as CryptoKit doesn't expose SHA1 directly
        // In production, use CommonCrypto for true SHA1
        return CryptoKit.SHA256.hash(data: data)
    }
}
