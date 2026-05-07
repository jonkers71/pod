import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var podcastService: PodcastIndexService
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @State private var selectedFilter: LibraryFilter = .all
    @State private var selectedPodcast: Podcast? = nil
    @State private var showDownloads: Bool = false

    enum LibraryFilter: String, CaseIterable {
        case all        = "All"
        case downloaded = "Downloaded"
        case inProgress = "In Progress"
    }

    // MARK: - Filtered Podcasts
    // "Downloaded" — shows podcasts that have at least one downloaded episode
    // "In Progress" — shows podcasts where at least one episode has been partially played
    var filteredPodcasts: [Podcast] {
        switch selectedFilter {
        case .all:
            return podcastService.subscribedPodcasts

        case .downloaded:
            // Show podcasts that have at least one downloaded episode
            return podcastService.subscribedPodcasts.filter { podcast in
                downloadManager.downloadedEpisodeIds.contains(where: { id in
                    id.hasPrefix(podcast.id)
                })
            }

        case .inProgress:
            // Show podcasts that have at least one episode with a saved playback position > 30s
            let positions = UserDefaults.standard.dictionary(forKey: "episodePositions") as? [String: Double] ?? [:]
            return podcastService.subscribedPodcasts.filter { podcast in
                positions.keys.contains(where: { key in
                    key.hasPrefix(podcast.id) && (positions[key] ?? 0) > 30
                })
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(LibraryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if podcastService.subscribedPodcasts.isEmpty {
                    emptyLibraryView
                } else if filteredPodcasts.isEmpty {
                    emptyFilterView
                } else {
                    subscribedList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDownloads = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(Color.accentTeal)
                            if !downloadManager.downloadedEpisodeIds.isEmpty {
                                Text("\(downloadManager.downloadedEpisodeIds.count)")
                                    .font(.caption2).fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Color.accentTeal)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedPodcast) { podcast in
                PodcastDetailView(podcast: podcast)
            }
            .sheet(isPresented: $showDownloads) {
                DownloadsView()
            }
        }
    }

    // MARK: - Empty States
    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Your Library is Empty")
                .font(.title2).fontWeight(.semibold)
            Text("Subscribe to podcasts to see them here.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var emptyFilterView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedFilter == .downloaded ? "arrow.down.circle" : "play.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(selectedFilter == .downloaded ? "No Downloads Yet" : "Nothing In Progress")
                .font(.title3).fontWeight(.semibold)
            Text(selectedFilter == .downloaded
                 ? "Tap the download button on any episode to save it for offline listening."
                 : "Episodes you have started but not finished will appear here.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Subscribed List
    private var subscribedList: some View {
        List {
            ForEach(filteredPodcasts) { podcast in
                PodcastRowView(podcast: podcast)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .onTapGesture { selectedPodcast = podcast }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            podcastService.unsubscribe(from: podcast)
                        } label: {
                            Label("Unsubscribe", systemImage: "trash")
                        }
                    }
            }
            Spacer(minLength: 80).listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Downloads View
struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if downloadManager.downloadedEpisodeIds.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 64)).foregroundColor(.secondary)
                        Text("No Downloads")
                            .font(.title2).fontWeight(.semibold)
                        Text("Downloaded episodes will appear here for offline listening.")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List {
                        Section(header:
                            HStack {
                                Text("Storage Used")
                                Spacer()
                                Text(downloadManager.totalDownloadedSize)
                                    .foregroundColor(.secondary)
                            }
                        ) {
                            ForEach(Array(downloadManager.downloadedEpisodeIds).sorted(), id: \.self) { episodeId in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(episodeId)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        downloadManager.deleteDownload(episodeId: episodeId)
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        Section {
                            Button(role: .destructive) {
                                for id in downloadManager.downloadedEpisodeIds {
                                    downloadManager.deleteDownload(episodeId: id)
                                }
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
