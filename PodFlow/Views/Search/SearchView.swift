import SwiftUI

struct SearchView: View {
    @EnvironmentObject var podcastService: PodcastIndexService
    @EnvironmentObject var spotifyService: SpotifyAuthService
    @State private var searchText: String = ""
    @State private var searchResults: [Podcast] = []
    @State private var spotifyResults: [SpotifyShow] = []
    @State private var isSearching: Bool = false
    @State private var selectedSource: SearchSource = .all
    @State private var selectedPodcast: Podcast? = nil
    @State private var debounceTask: Task<Void, Never>? = nil

    enum SearchSource: String, CaseIterable {
        case all = "All"
        case podcasts = "Podcasts"
        case spotify = "Spotify"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Source Picker
                Picker("Source", selection: $selectedSource) {
                    ForEach(SearchSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if searchText.isEmpty {
                    emptySearchView
                } else if isSearching {
                    loadingView
                } else {
                    resultsView
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search podcasts...")
            .onChange(of: searchText) { _, newValue in
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                    if !Task.isCancelled {
                        await performSearch(query: newValue)
                    }
                }
            }
            .navigationDestination(item: $selectedPodcast) { podcast in
                PodcastDetailView(podcast: podcast)
            }
        }
    }

    // MARK: - Empty State
    private var emptySearchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Browse Categories")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(PodcastCategory.all) { category in
                        CategoryGridItem(category: category)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 80)
            }
            .padding(.top)
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results
    private var resultsView: some View {
        List {
            if !searchResults.isEmpty {
                Section("Podcasts") {
                    ForEach(searchResults) { podcast in
                        PodcastRowView(podcast: podcast)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .onTapGesture { selectedPodcast = podcast }
                    }
                }
            }

            if !spotifyResults.isEmpty {
                Section("Spotify Shows") {
                    ForEach(spotifyResults) { show in
                        SpotifyShowRowView(show: show)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                }
            }

            if searchResults.isEmpty && spotifyResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No podcasts found for \"\(searchText)\"")
                )
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden).background(Color.appBackground)
    }

    // MARK: - Search
    @MainActor
    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            spotifyResults = []
            return
        }

        isSearching = true

        // Capture values on main actor before entering concurrent work
        let source = selectedSource
        let isSpotifyAuth = spotifyService.isAuthenticated

        var podcasts: [Podcast] = []
        var shows: [SpotifyShow] = []

        if source == .all || source == .podcasts {
            podcasts = (try? await podcastService.searchPodcasts(query: query))
                ?? Podcast.mockPodcasts.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        if (source == .all || source == .spotify) && isSpotifyAuth {
            shows = (try? await spotifyService.searchShows(query: query)) ?? []
        }

        searchResults = podcasts
        spotifyResults = shows
        isSearching = false
    }
}

// MARK: - Category Grid Item
struct CategoryGridItem: View {
    let category: PodcastCategory

    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.title2)
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding()
        .background(category.color.opacity(0.15))
        .foregroundColor(category.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Spotify Show Row
struct SpotifyShowRowView: View {
    let show: SpotifyShow

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: show.imageURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBackground.opacity(0.7))
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(show.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Text(show.publisher)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .font(.caption2)
                    Text("Spotify")
                        .font(.caption2)
                }
                .foregroundColor(.green)
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .foregroundColor(.green)
                .font(.caption)
        }
        .padding(12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
