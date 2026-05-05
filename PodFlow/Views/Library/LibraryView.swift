import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var podcastService: PodcastIndexService
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var selectedFilter: LibraryFilter = .all
    @State private var selectedPodcast: Podcast? = nil
    @State private var showDownloads: Bool = false

    enum LibraryFilter: String, CaseIterable {
        case all = "All"
        case downloaded = "Downloaded"
        case inProgress = "In Progress"
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
                } else {
                    subscribedList
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDownloads = true
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(Color("AccentBlue"))
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

    // MARK: - Empty State
    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Your Library is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Subscribe to podcasts to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Subscribed List
    private var subscribedList: some View {
        List {
            ForEach(podcastService.subscribedPodcasts) { podcast in
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
            Spacer(minLength: 80)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
}

// MARK: - Downloads View
struct DownloadsView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if downloadManager.downloadedEpisodeIds.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("No Downloads")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Downloaded episodes will appear here for offline listening.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List {
                        Section(header: Text("Storage Used: \(downloadManager.totalDownloadedSize)")) {
                            ForEach(Array(downloadManager.downloadedEpisodeIds), id: \.self) { episodeId in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(episodeId)
                                        .font(.subheadline)
                                    Spacer()
                                    Button {
                                        downloadManager.deleteDownload(episodeId: episodeId)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
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
