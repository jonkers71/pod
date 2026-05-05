import Foundation
import SwiftUI

// MARK: - Podcast Model
struct Podcast: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var author: String
    var description: String
    var imageURL: String
    var feedURL: String
    var categories: [String]
    var episodeCount: Int
    var isSubscribed: Bool = false
    var lastUpdated: Date?
    var source: PodcastSource = .podcastIndex

    enum PodcastSource: String, Codable {
        case podcastIndex
        case spotify
        case rss
    }

    static let placeholder = Podcast(
        id: "placeholder",
        title: "Sample Podcast",
        author: "Sample Author",
        description: "A great podcast about everything.",
        imageURL: "",
        feedURL: "",
        categories: ["Technology"],
        episodeCount: 100
    )
}

// MARK: - Episode Model
struct Episode: Identifiable, Codable, Hashable {
    let id: String
    var podcastId: String
    var podcastTitle: String
    var podcastImageURL: String
    var title: String
    var description: String
    var audioURL: String
    var duration: TimeInterval
    var publishDate: Date
    var imageURL: String?
    var chapterMarkers: [ChapterMarker]?
    var transcript: [TranscriptSegment]?
    var isDownloaded: Bool = false
    var localFilePath: String?
    var playbackPosition: TimeInterval = 0
    var isPlayed: Bool = false
    var snips: [Snip] = []
    var episodeNumber: Int?
    var season: Int?

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedPublishDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishDate, relativeTo: Date())
    }
}

// MARK: - Chapter Marker
struct ChapterMarker: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var startTime: TimeInterval
    var endTime: TimeInterval?
    var imageURL: String?
    var url: String?
}

// MARK: - Transcript Segment
struct TranscriptSegment: Identifiable, Codable, Hashable {
    let id: String
    var speaker: String?
    var text: String
    var startTime: TimeInterval
    var endTime: TimeInterval
}

// MARK: - Snip Model (saved audio clip)
struct Snip: Identifiable, Codable, Hashable {
    let id: String
    var episodeId: String
    var episodeTitle: String
    var podcastTitle: String
    var podcastImageURL: String
    var startTime: TimeInterval
    var endTime: TimeInterval
    var text: String          // transcript text for this snip
    var summary: String       // AI-generated summary
    var createdAt: Date
    var tags: [String] = []
    var note: String = ""

    var duration: TimeInterval { endTime - startTime }
}

// MARK: - Playlist / Queue
struct PlaybackQueue: Codable {
    var episodes: [Episode]
    var currentIndex: Int = 0

    var currentEpisode: Episode? {
        guard currentIndex < episodes.count else { return nil }
        return episodes[currentIndex]
    }
}

// MARK: - User Subscription Tier
enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    case lifetime = "lifetime"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .lifetime: return "Lifetime"
        }
    }

    var isAdsEnabled: Bool {
        return self == .free
    }

    var hasUnlimitedAI: Bool {
        return self != .free
    }

    var maxSnipsPerMonth: Int {
        switch self {
        case .free: return 5
        case .premium, .lifetime: return Int.max
        }
    }
}

// MARK: - Search Result
struct SearchResult: Identifiable {
    let id = UUID()
    var podcasts: [Podcast]
    var episodes: [Episode]
}

// MARK: - Podcast Index API Response
struct PodcastIndexSearchResponse: Codable {
    let feeds: [PodcastIndexFeed]?
    let count: Int?
    let description: String?
}

struct PodcastIndexFeed: Codable {
    let id: Int
    let title: String
    let url: String
    let originalUrl: String?
    let link: String?
    let description: String?
    let author: String?
    let ownerName: String?
    let image: String?
    let artwork: String?
    let episodeCount: Int?
    let categories: [String: String]?
    let language: String?
    let explicit: Bool?
}

struct PodcastIndexEpisodesResponse: Codable {
    let items: [PodcastIndexEpisode]?
    let count: Int?
}

struct PodcastIndexEpisode: Codable {
    let id: Int
    let title: String?
    let description: String?
    let guid: String?
    let datePublished: TimeInterval?
    let enclosureUrl: String?
    let enclosureLength: Int?
    let duration: Int?
    let image: String?
    let feedImage: String?
    let feedId: Int?
    let feedTitle: String?
    let chaptersUrl: String?
    let transcriptUrl: String?
    let episode: Int?
    let season: Int?
}

// MARK: - Spotify Models
struct SpotifyShow: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let publisher: String
    let images: [SpotifyImage]
    let totalEpisodes: Int?

    var imageURL: String { images.first?.url ?? "" }

    enum CodingKeys: String, CodingKey {
        case id, name, description, publisher, images
        case totalEpisodes = "total_episodes"
    }
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyEpisode: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let durationMs: Int
    let releaseDate: String
    let audioPreviewUrl: String?
    let images: [SpotifyImage]
    let externalUrls: SpotifyExternalUrls

    var imageURL: String { images.first?.url ?? "" }
    var durationSeconds: TimeInterval { TimeInterval(durationMs) / 1000 }

    enum CodingKeys: String, CodingKey {
        case id, name, description, images
        case durationMs = "duration_ms"
        case releaseDate = "release_date"
        case audioPreviewUrl = "audio_preview_url"
        case externalUrls = "external_urls"
    }
}

struct SpotifyExternalUrls: Codable {
    let spotify: String?
}

// MARK: - Download State
enum DownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(error: String)
}

// MARK: - Category
struct PodcastCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let color: Color
}

extension PodcastCategory {
    static let all: [PodcastCategory] = [
        PodcastCategory(id: "technology", name: "Technology", icon: "cpu", color: .blue),
        PodcastCategory(id: "business", name: "Business", icon: "briefcase", color: .green),
        PodcastCategory(id: "comedy", name: "Comedy", icon: "face.smiling", color: .yellow),
        PodcastCategory(id: "news", name: "News", icon: "newspaper", color: .red),
        PodcastCategory(id: "true-crime", name: "True Crime", icon: "magnifyingglass", color: .purple),
        PodcastCategory(id: "education", name: "Education", icon: "book", color: .orange),
        PodcastCategory(id: "health", name: "Health", icon: "heart", color: .pink),
        PodcastCategory(id: "sports", name: "Sports", icon: "sportscourt", color: .teal),
        PodcastCategory(id: "science", name: "Science", icon: "atom", color: .indigo),
        PodcastCategory(id: "history", name: "History", icon: "clock.arrow.circlepath", color: .brown)
    ]
}
