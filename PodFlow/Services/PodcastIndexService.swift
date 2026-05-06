import Foundation
import CryptoKit
import Combine

class PodcastIndexService: ObservableObject {
    static let shared = PodcastIndexService()

    private let baseURL = "https://api.podcastindex.org/api/1.0"

    @Published var trendingPodcasts: [Podcast] = []
    @Published var subscribedPodcasts: [Podcast] = []
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadSubscribedPodcasts()
    }

    // MARK: - Obfuscated Credentials
    // Keys are XOR-obfuscated at rest. No plaintext credentials in this file.
    // To rotate: re-run obfuscate_keys.py with new credentials and replace the arrays below.

    private static let _podcastIndexKeySalt: [UInt8] = [32, 8, 221, 124, 107, 17, 45, 253, 103, 215, 236, 161, 86, 25, 85, 133, 92, 241, 20, 55]
    private static let _podcastIndexKeyData: [UInt8] = [114, 90, 135, 72, 44, 68, 125, 191, 82, 145, 223, 242, 6, 65, 15, 201, 100, 187, 77, 15]
    private static var podcastIndexKey: String {
        String(bytes: zip(_podcastIndexKeyData, _podcastIndexKeySalt).map { $0 ^ $1 }, encoding: .utf8) ?? ""
    }

    private static let _podcastIndexSecretSalt: [UInt8] = [221, 158, 34, 64, 242, 95, 226, 136, 218, 95, 100, 173, 92, 119, 222, 120, 98, 185, 194, 51, 61, 5, 172, 77, 170, 55, 100, 51, 110, 130, 44, 145, 52, 249, 201, 48, 200, 200, 50, 109]
    private static let _podcastIndexSecretData: [UInt8] = [188, 206, 120, 38, 181, 13, 209, 238, 190, 108, 12, 230, 58, 84, 169, 31, 60, 212, 135, 87, 109, 127, 254, 31, 157, 100, 33, 11, 40, 176, 31, 201, 77, 171, 139, 3, 178, 165, 74, 27]
    private static var podcastIndexSecret: String {
        String(bytes: zip(_podcastIndexSecretData, _podcastIndexSecretSalt).map { $0 ^ $1 }, encoding: .utf8) ?? ""
    }

    // MARK: - Auth Headers
    private func authHeaders() -> [String: String] {
        let apiKey    = PodcastIndexService.podcastIndexKey
        let apiSecret = PodcastIndexService.podcastIndexSecret
        let epochTime = Int(Date().timeIntervalSince1970)
        let hashInput = "\(apiKey)\(apiSecret)\(epochTime)"
        let hash      = Insecure.SHA1.hash(data: Data(hashInput.utf8))
            .map { String(format: "%02hhx", $0) }.joined()

        return [
            "X-Auth-Date": "\(epochTime)",
            "X-Auth-Key":  apiKey,
            "Authorization": hash,
            "User-Agent":  "PodFlow/1.0"
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
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
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
