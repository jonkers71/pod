import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        // Adaptive layout: iPad uses sidebar, iPhone uses tab bar
        if horizontalSizeClass == .regular {
            iPadRootView()
        } else {
            iPhoneRootView()
        }
    }
}

// MARK: - iPhone Root (Tab Bar)
struct iPhoneRootView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab: AppTab = .discover
    @State private var showFullPlayer: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DiscoverView()
                    .tabItem { Label("Discover", systemImage: "house.fill") }
                    .tag(AppTab.discover)

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(AppTab.search)

                LibraryView()
                    .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                    .tag(AppTab.library)

                SnipsView()
                    .tabItem { Label("Snips", systemImage: "scissors") }
                    .tag(AppTab.snips)

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(AppTab.profile)
            }
            .accentColor(Color.accentTeal)

            // Floating Mini Player above tab bar
            if audioPlayerManager.currentEpisode != nil {
                VStack(spacing: 0) {
                    MiniPlayerView(showFullPlayer: $showFullPlayer)
                }
                .padding(.bottom, 49)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: audioPlayerManager.currentEpisode != nil)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
    }
}

// MARK: - iPad Root (NavigationSplitView Sidebar)
struct iPadRootView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @State private var selectedTab: AppTab = .discover
    @State private var showFullPlayer: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            iPadSidebar(selectedTab: $selectedTab)
        } detail: {
            // Main Content
            ZStack(alignment: .bottomTrailing) {
                Group {
                    switch selectedTab {
                    case .discover: DiscoverView()
                    case .search:   SearchView()
                    case .library:  LibraryView()
                    case .snips:    SnipsView()
                    case .profile:  ProfileView()
                    }
                }

                // Floating mini player in bottom-right corner on iPad
                if audioPlayerManager.currentEpisode != nil {
                    MiniPlayerView(showFullPlayer: $showFullPlayer)
                        .frame(maxWidth: 400)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: audioPlayerManager.currentEpisode != nil)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
                .presentationDetents([.large])
        }
    }
}

// MARK: - iPad Sidebar
struct iPadSidebar: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var podcastService: PodcastIndexService

    var body: some View {
        List(selection: $selectedTab) {
            Section("Menu") {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }

            if !podcastService.subscribedPodcasts.isEmpty {
                Section("Subscriptions") {
                    ForEach(podcastService.subscribedPodcasts.prefix(8)) { podcast in
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: podcast.imageURL)) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.appBackground.opacity(0.7)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            Text(podcast.title)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PodFlow")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - App Tab Enum
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case discover, search, library, snips, profile
    var id: String { rawValue }

    var title: String {
        switch self {
        case .discover: return "Discover"
        case .search:   return "Search"
        case .library:  return "Library"
        case .snips:    return "Snips"
        case .profile:  return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .discover: return "house.fill"
        case .search:   return "magnifyingglass"
        case .library:  return "books.vertical.fill"
        case .snips:    return "scissors"
        case .profile:  return "person.fill"
        }
    }
}
