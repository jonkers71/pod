import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
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

            // Mini player sits above the tab bar
            // Uses safeAreaInsets to correctly position above home indicator
            if audioPlayerManager.currentEpisode != nil {
                MiniPlayerBar(showFullPlayer: $showFullPlayer)
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

// MARK: - Mini Player Bar (correctly positioned above tab bar)
struct MiniPlayerBar: View {
    @Binding var showFullPlayer: Bool

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                MiniPlayerView(showFullPlayer: $showFullPlayer)
                    // Sit exactly on top of the tab bar (49pt) plus safe area bottom inset
                    .padding(.bottom, 49 + geo.safeAreaInsets.bottom)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - iPad Root (NavigationSplitView)
struct iPadRootView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @State private var selectedTab: AppTab = .discover
    @State private var showFullPlayer: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            iPadSidebar(selectedTab: $selectedTab)
        } detail: {
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
        List {
            Section("Menu") {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .foregroundColor(selectedTab == tab ? Color.accentTeal : .primary)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTab = tab }
                        .listRowBackground(
                            selectedTab == tab
                                ? Color.accentTeal.opacity(0.12)
                                : Color.clear
                        )
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
