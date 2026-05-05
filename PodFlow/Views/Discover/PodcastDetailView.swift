import SwiftUI

struct PodcastDetailView: View {
    let podcast: Podcast
    @EnvironmentObject var podcastService: PodcastIndexService
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var episodes: [Episode] = []
    @State private var isLoading: Bool = true
    @State private var isSubscribed: Bool = false
    @State private var showDescription: Bool = false
    @State private var sortNewestFirst: Bool = true

    var sortedEpisodes: [Episode] {
        sortNewestFirst ? episodes : episodes.reversed()
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadContent() }
    }

    // MARK: - iPhone Layout
    private var iPhoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                podcastHeader
                    .padding(.horizontal)
                    .padding(.top, 16)
                episodeListSection
                Spacer(minLength: 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                subscribeButton
            }
        }
    }

    // MARK: - iPad Layout (two-column)
    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left panel: artwork + info
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    podcastHeader
                    subscribeButton
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentTeal)
                    descriptionSection
                    Spacer()
                }
                .padding(24)
            }
            .frame(maxWidth: 340)
            .background(Color(.systemGroupedBackground))

            Divider()

            // Right panel: episodes
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    episodeListSection
                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(podcast.title)
    }

    // MARK: - Podcast Header
    private var podcastHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: URL(string: podcast.imageURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appBackground.opacity(0.7))
                    .overlay(Image(systemName: "mic.fill").font(.title).foregroundColor(.gray))
            }
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(podcast.title)
                    .font(.title3).fontWeight(.bold)
                    .lineLimit(3)
                Text(podcast.author)
                    .font(.subheadline).foregroundColor(Color.accentTeal)
                if !podcast.categories.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(podcast.categories.prefix(2), id: \.self) { cat in
                            Text(cat)
                                .font(.caption2)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.accentTeal.opacity(0.12))
                                .foregroundColor(Color.accentTeal)
                                .clipShape(Capsule())
                        }
                    }
                }
                Text("\(podcast.episodeCount) episodes")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(podcast.description)
                .font(.subheadline).foregroundColor(.secondary)
                .lineLimit(showDescription ? nil : 3)
            Button(showDescription ? "Show less" : "Show more") {
                withAnimation { showDescription.toggle() }
            }
            .font(.caption).foregroundColor(Color.accentTeal)
        }
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                if isSubscribed {
                    podcastService.unsubscribe(from: podcast)
                } else {
                    podcastService.subscribe(to: podcast)
                }
                isSubscribed.toggle()
            }
        } label: {
            Label(
                isSubscribed ? "Subscribed" : "Subscribe",
                systemImage: isSubscribed ? "checkmark.circle.fill" : "plus.circle"
            )
            .font(.subheadline).fontWeight(.semibold)
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(isSubscribed ? Color.appBackground.opacity(0.7) : Color.accentTeal)
            .foregroundColor(isSubscribed ? .primary : .white)
            .clipShape(Capsule())
        }
    }

    // MARK: - Episode List
    private var episodeListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Episodes")
                    .font(.headline)
                    .padding(.horizontal)
                Spacer()
                Button {
                    withAnimation { sortNewestFirst.toggle() }
                } label: {
                    Label(sortNewestFirst ? "Newest" : "Oldest",
                          systemImage: sortNewestFirst ? "arrow.down" : "arrow.up")
                        .font(.caption).foregroundColor(Color.accentTeal)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            if isLoading {
                ForEach(0..<5, id: \.self) { _ in
                    EpisodeRowSkeleton()
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            } else {
                ForEach(sortedEpisodes) { episode in
                    EpisodeRowView(episode: episode)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Load
    private func loadContent() async {
        isSubscribed = podcastService.isSubscribed(to: podcast)
        do {
            episodes = try await podcastService.fetchEpisodes(for: podcast)
        } catch {
            episodes = Episode.mockEpisodes(for: podcast)
        }
        isLoading = false
    }
}

// MARK: - Episode Row
struct EpisodeRowView: View {
    let episode: Episode
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showActions: Bool = false

    var isCurrentlyPlaying: Bool {
        audioPlayerManager.currentEpisode?.id == episode.id && audioPlayerManager.isPlaying
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Play button
                Button {
                    if audioPlayerManager.currentEpisode?.id == episode.id {
                        audioPlayerManager.togglePlayPause()
                    } else {
                        audioPlayerManager.load(episode: episode)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isCurrentlyPlaying ? Color.accentTeal : Color.appBackground.opacity(0.7))
                            .frame(width: 44, height: 44)
                        Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isCurrentlyPlaying ? .white : .primary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.title)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(isCurrentlyPlaying ? Color.accentTeal : .primary)

                    HStack(spacing: 8) {
                        Text(episode.formattedPublishDate)
                            .font(.caption).foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(episode.formattedDuration)
                            .font(.caption).foregroundColor(.secondary)
                    }

                    // Progress bar if partially played
                    if episode.playbackPosition > 0 && !episode.isPlayed {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.appBackground.opacity(0.7)).frame(height: 3)
                                Capsule()
                                    .fill(Color.accentTeal)
                                    .frame(width: geo.size.width * (episode.playbackPosition / max(episode.duration, 1)), height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Download / more menu
                VStack(spacing: 8) {
                    downloadButton
                    Button { showActions = true } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .padding(12)

            Divider().padding(.leading, 68)
        }
        .background(Color.appSurface)
        .confirmationDialog(episode.title, isPresented: $showActions) {
            Button("Play Next") { audioPlayerManager.addToQueueNext(episode) }
            Button("Add to Queue") { audioPlayerManager.addToQueue(episode) }
            Button("Share Episode") { shareEpisode() }
            if downloadManager.isDownloaded(episodeId: episode.id) {
                Button("Delete Download", role: .destructive) {
                    downloadManager.deleteDownload(episodeId: episode.id)
                }
            } else {
                Button("Download Episode") { downloadManager.download(episode: episode) }
            }
        }
    }

    @ViewBuilder
    private var downloadButton: some View {
        let state = downloadManager.downloadState(for: episode.id)
        switch state {
        case .notDownloaded:
            Button { downloadManager.download(episode: episode) } label: {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.secondary).font(.title3)
            }
        case .downloading(let progress):
            ZStack {
                Circle().stroke(Color(.systemGray4), lineWidth: 2).frame(width: 24, height: 24)
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.accentTeal, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 24, height: 24)
                Button { downloadManager.cancelDownload(episodeId: episode.id) } label: {
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.secondary)
                }
            }
        case .downloaded:
            Button { downloadManager.deleteDownload(episodeId: episode.id) } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.accentGreen).font(.title3)
            }
        case .failed:
            Button { downloadManager.download(episode: episode) } label: {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red).font(.title3)
            }
        }
    }

    private func shareEpisode() {
        let text = "Check out \"\(episode.title)\" from \(episode.podcastTitle) on PodFlow"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
}

// MARK: - Episode Row Skeleton
struct EpisodeRowSkeleton: View {
    @State private var animating = false
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color.appBackground.opacity(0.7)).frame(width: 44, height: 44).shimmer(isAnimating: animating)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.appBackground.opacity(0.7)).frame(height: 14).shimmer(isAnimating: animating)
                RoundedRectangle(cornerRadius: 4).fill(Color.appBackground.opacity(0.7)).frame(width: 120, height: 10).shimmer(isAnimating: animating)
            }
            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Mock Episodes
extension Episode {
    static func mockEpisodes(for podcast: Podcast) -> [Episode] {
        (1...10).map { i in
            Episode(
                id: "\(podcast.id)_ep\(i)",
                podcastId: podcast.id,
                podcastTitle: podcast.title,
                podcastImageURL: podcast.imageURL,
                title: "Episode \(i): A Deep Dive into Topic \(i)",
                description: "In this episode we explore fascinating ideas and discuss the latest developments.",
                audioURL: "https://example.com/episode\(i).mp3",
                duration: TimeInterval(1800 + i * 300),
                publishDate: Date().addingTimeInterval(TimeInterval(-i * 86400 * 3))
            )
        }
    }
}
