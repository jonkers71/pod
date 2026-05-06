import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let badge: PageBadge?
    let features: [OnboardingFeature]
    let accentColor: Color
    let gradient: [Color]

    enum PageBadge {
        case live
        case comingSoon
    }
}

struct OnboardingFeature {
    let text: String
    let isLive: Bool
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var currentPage: Int = 0

    let pages: [OnboardingPage] = [

        // Page 1 — Welcome
        OnboardingPage(
            icon: "waveform",
            title: "Welcome to PodFlow",
            description: "The smarter way to listen. Discover millions of podcasts, download for offline listening, and never miss an episode.",
            badge: nil,
            features: [
                OnboardingFeature(text: "4.5 million podcasts via Podcast Index", isLive: true),
                OnboardingFeature(text: "Offline downloads for listening anywhere", isLive: true),
                OnboardingFeature(text: "Variable speed, sleep timer, CarPlay support", isLive: true),
                OnboardingFeature(text: "Adaptive layout for iPhone and iPad", isLive: true),
            ],
            accentColor: Color.accentTeal,
            gradient: [Color.accentTeal, Color.accentPurple]
        ),

        // Page 2 — Snips
        OnboardingPage(
            icon: "scissors",
            title: "Snip & Save Insights",
            description: "Tap the scissors button while listening to save any moment as a clip with a timestamp and note.",
            badge: .live,
            features: [
                OnboardingFeature(text: "Save clips with timestamps and notes", isLive: true),
                OnboardingFeature(text: "Export snips as Markdown to any app", isLive: true),
                OnboardingFeature(text: "AI-generated summaries for each snip", isLive: false),
                OnboardingFeature(text: "Direct sync to Notion and Obsidian", isLive: false),
            ],
            accentColor: Color.accentOrange,
            gradient: [Color.accentOrange, .red]
        ),

        // Page 3 — Transcripts
        OnboardingPage(
            icon: "text.alignleft",
            title: "Transcripts",
            description: "Read along with auto-scrolling transcripts for supported podcasts. Tap any line to jump to that moment.",
            badge: .live,
            features: [
                OnboardingFeature(text: "Auto-scrolling transcripts (Podcasting 2.0 shows)", isLive: true),
                OnboardingFeature(text: "Tap any line to jump to that moment", isLive: true),
                OnboardingFeature(text: "AI transcription for all podcasts", isLive: false),
                OnboardingFeature(text: "Search any word across your entire library", isLive: false),
            ],
            accentColor: Color.accentPurple,
            gradient: [Color.accentPurple, Color.accentTeal]
        ),

        // Page 4 — Offline & Downloads
        OnboardingPage(
            icon: "arrow.down.circle.fill",
            title: "Listen Offline",
            description: "Download any episode over Wi-Fi and listen anywhere — on a plane, underground, or wherever you go.",
            badge: .live,
            features: [
                OnboardingFeature(text: "Background downloads continue when app is closed", isLive: true),
                OnboardingFeature(text: "Download progress shown on every episode", isLive: true),
                OnboardingFeature(text: "Storage manager to clear old downloads", isLive: true),
                OnboardingFeature(text: "Auto-download new episodes on Wi-Fi", isLive: true),
            ],
            accentColor: .green,
            gradient: [.green, Color.accentTeal]
        ),

        // Page 5 — Personalisation & Social
        OnboardingPage(
            icon: "sparkles",
            title: "What's Coming",
            description: "PodFlow is just getting started. Here is what we are building next — features that will roll out as our community grows.",
            badge: .comingSoon,
            features: [
                OnboardingFeature(text: "Personalised recommendations based on your library", isLive: false),
                OnboardingFeature(text: "Friend activity — see what others are listening to", isLive: false),
                OnboardingFeature(text: "Timestamped comments on episodes", isLive: false),
                OnboardingFeature(text: "AI Radio — a personalised episode feed", isLive: false),
            ],
            accentColor: Color.accentPink,
            gradient: [Color.accentPink, Color.accentPurple]
        ),

        // Page 6 — Spotify
        OnboardingPage(
            icon: "music.note.list",
            title: "Connect Spotify",
            description: "Link your Spotify account to see your saved shows alongside your RSS subscriptions in one place.",
            badge: .live,
            features: [
                OnboardingFeature(text: "See your Spotify saved shows in PodFlow", isLive: true),
                OnboardingFeature(text: "Search Spotify's podcast catalog", isLive: true),
                OnboardingFeature(text: "Spotify-exclusive shows open in Spotify app", isLive: true),
                OnboardingFeature(text: "In-app Spotify audio playback", isLive: false),
            ],
            accentColor: .green,
            gradient: [.green, .teal]
        ),
    ]

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation { currentPage = pages.count - 1 }
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    }
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 480)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(
                                width: currentPage == index ? 10 : 7,
                                height: currentPage == index ? 10 : 7
                            )
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 16)

                Spacer()

                // CTA Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4)) { currentPage += 1 }
                    } else {
                        userSettings.hasCompletedOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(pages[currentPage].accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 20) {
            // Badge
            if let badge = page.badge {
                Text(badge == .live ? "✦ LIVE NOW" : "🗺 ROADMAP")
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(Color.white.opacity(0.25))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: page.icon)
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }

            // Title + description
            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Feature list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.features, id: \.text) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: feature.isLive ? "checkmark.circle.fill" : "clock.circle")
                            .font(.subheadline)
                            .foregroundColor(feature.isLive ? .white : .white.opacity(0.5))
                        Text(feature.text)
                            .font(.subheadline)
                            .foregroundColor(feature.isLive ? .white : .white.opacity(0.55))
                        if !feature.isLive {
                            Text("Soon")
                                .font(.caption2).fontWeight(.semibold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white.opacity(0.7))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Onboarding Gate
struct OnboardingGate: View {
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        if userSettings.hasCompletedOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
