import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var podcastService: PodcastIndexService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var trendingPodcasts: [Podcast] = []
    @State private var selectedCategory: PodcastCategory? = nil
    @State private var isLoading: Bool = false
    @State private var selectedPodcast: Podcast? = nil

    // Adaptive grid: 2 cols on iPhone, 4 cols on iPad
    var gridColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Ad Banner (Free tier only)
                    if subscriptionManager.currentTier.isAdsEnabled {
                        AdBannerView()
                            .padding(.horizontal)
                    }

                    // Category Chips
                    categoryScrollView

                    // Trending – horizontal scroll on iPhone, grid on iPad
                    if horizontalSizeClass == .regular {
                        trendingGridSection
                    } else {
                        trendingScrollSection
                    }

                    // Featured / Editor's Picks
                    featuredSection

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .foregroundColor(Color.accentTeal)
                    }
                }
            }
            .task { await loadTrending() }
            .refreshable { await loadTrending() }
            .navigationDestination(item: $selectedPodcast) { podcast in
                PodcastDetailView(podcast: podcast)
            }
        }
    }

    // MARK: - Category Chips
    private var categoryScrollView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Browse by Category")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PodcastCategory.all) { category in
                        CategoryChipView(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        )
                        .onTapGesture {
                            selectedCategory = selectedCategory?.id == category.id ? nil : category
                            Task { await loadTrending() }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Trending Horizontal Scroll (iPhone)
    private var trendingScrollSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Trending Now")
            if isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<6, id: \.self) { _ in PodcastCardSkeleton() }
                    }.padding(.horizontal)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(trendingPodcasts) { podcast in
                            PodcastCardView(podcast: podcast)
                                .onTapGesture { selectedPodcast = podcast }
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Trending Grid (iPad)
    private var trendingGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Trending Now")
            if isLoading {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(0..<8, id: \.self) { _ in PodcastCardSkeleton() }
                }.padding(.horizontal)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(trendingPodcasts) { podcast in
                        PodcastCardView(podcast: podcast)
                            .onTapGesture { selectedPodcast = podcast }
                    }
                }.padding(.horizontal)
            }
        }
    }

    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Editor's Picks")
            LazyVStack(spacing: 12) {
                ForEach(trendingPodcasts.prefix(horizontalSizeClass == .regular ? 10 : 5)) { podcast in
                    PodcastRowView(podcast: podcast)
                        .padding(.horizontal)
                        .onTapGesture { selectedPodcast = podcast }
                }
            }
        }
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Button("See All") {}
                .font(.subheadline).foregroundColor(Color.accentTeal)
        }.padding(.horizontal)
    }

    private func loadTrending() async {
        isLoading = true
        do {
            trendingPodcasts = try await podcastService.fetchTrending(category: selectedCategory?.name)
        } catch {
            trendingPodcasts = Podcast.mockPodcasts
        }
        isLoading = false
    }
}

// MARK: - Category Chip
struct CategoryChipView: View {
    let category: PodcastCategory
    let isSelected: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon).font(.caption)
            Text(category.name).font(.subheadline).fontWeight(.medium)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(isSelected ? category.color : Color.appBackground)
        .foregroundColor(isSelected ? .white : .primary)
        .clipShape(Capsule())
    }
}

// MARK: - Podcast Card (Horizontal / Grid)
struct PodcastCardView: View {
    let podcast: Podcast
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: podcast.imageURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackground.opacity(0.7))
                    .overlay(Image(systemName: "mic.fill").foregroundColor(.gray))
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(podcast.title)
                .font(.caption).fontWeight(.semibold)
                .lineLimit(2).frame(width: 140, alignment: .leading)
            Text(podcast.author)
                .font(.caption2).foregroundColor(.secondary)
                .lineLimit(1).frame(width: 140, alignment: .leading)
        }
    }
}

// MARK: - Podcast Row
struct PodcastRowView: View {
    let podcast: Podcast
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: podcast.imageURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBackground.opacity(0.7))
                    .overlay(Image(systemName: "mic.fill").foregroundColor(.gray))
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.title).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                Text(podcast.author).font(.caption).foregroundColor(.secondary)
                if let cat = podcast.categories.first {
                    Text(cat)
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.accentTeal.opacity(0.15))
                        .foregroundColor(Color.accentTeal)
                        .clipShape(Capsule())
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
        }
        .padding(12)
        .glassCard(cornerRadius: 12)
    }
}

// MARK: - Skeleton
struct PodcastCardSkeleton: View {
    @State private var isAnimating = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12).fill(Color.appBackground.opacity(0.7))
                .frame(width: 140, height: 140).shimmer(isAnimating: isAnimating)
            RoundedRectangle(cornerRadius: 4).fill(Color.appBackground.opacity(0.7))
                .frame(width: 120, height: 12).shimmer(isAnimating: isAnimating)
            RoundedRectangle(cornerRadius: 4).fill(Color.appBackground.opacity(0.7))
                .frame(width: 80, height: 10).shimmer(isAnimating: isAnimating)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Mock Data
extension Podcast {
    static let mockPodcasts: [Podcast] = [
        Podcast(id: "1", title: "The Daily", author: "The New York Times", description: "This is what the news should sound like.", imageURL: "", feedURL: "", categories: ["News"], episodeCount: 1500),
        Podcast(id: "2", title: "Lex Fridman Podcast", author: "Lex Fridman", description: "Conversations about science, technology, history and philosophy.", imageURL: "", feedURL: "", categories: ["Technology"], episodeCount: 400),
        Podcast(id: "3", title: "Serial", author: "Serial Productions", description: "Investigative journalism at its finest.", imageURL: "", feedURL: "", categories: ["True Crime"], episodeCount: 50),
        Podcast(id: "4", title: "How I Built This", author: "NPR", description: "Stories behind the world's best known companies.", imageURL: "", feedURL: "", categories: ["Business"], episodeCount: 300),
        Podcast(id: "5", title: "Stuff You Should Know", author: "iHeartPodcasts", description: "Learn about everything.", imageURL: "", feedURL: "", categories: ["Education"], episodeCount: 1800),
        Podcast(id: "6", title: "Hidden Brain", author: "NPR", description: "Shankar Vedantam uses science and storytelling to reveal the unconscious patterns that drive human behaviour.", imageURL: "", feedURL: "", categories: ["Science"], episodeCount: 250),
        Podcast(id: "7", title: "Crime Junkie", author: "audiochuck", description: "A weekly true crime podcast.", imageURL: "", feedURL: "", categories: ["True Crime"], episodeCount: 350),
        Podcast(id: "8", title: "Conan O'Brien Needs a Friend", author: "Team Coco", description: "Conan O'Brien is a lonely man.", imageURL: "", feedURL: "", categories: ["Comedy"], episodeCount: 200),
    ]
}
