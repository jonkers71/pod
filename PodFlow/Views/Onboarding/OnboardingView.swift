import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var currentPage: Int = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform",
            title: "Welcome to PodFlow",
            description: "The smarter way to listen. Discover millions of podcasts, download for offline listening, and never miss an episode.",
            accentColor: Color("AccentBlue"),
            gradient: [Color("AccentBlue"), Color("AccentPurple")]
        ),
        OnboardingPage(
            icon: "scissors",
            title: "Snip & Save Insights",
            description: "Tap the snip button to save any moment with a transcript and AI summary. Export to Notion, Obsidian, or share with friends.",
            accentColor: Color("AccentOrange"),
            gradient: [Color("AccentOrange"), Color.red]
        ),
        OnboardingPage(
            icon: "text.alignleft",
            title: "AI-Powered Transcripts",
            description: "Read along with auto-scrolling transcripts. Search any word spoken across your entire library. Jump to any moment instantly.",
            accentColor: Color("AccentPurple"),
            gradient: [Color("AccentPurple"), Color("AccentBlue")]
        ),
        OnboardingPage(
            icon: "arrow.down.circle.fill",
            title: "Listen Offline",
            description: "Download any episode over Wi-Fi and listen anywhere — on a plane, underground, or wherever you go.",
            accentColor: .green,
            gradient: [.green, Color("AccentBlue")]
        ),
        OnboardingPage(
            icon: "music.note.list",
            title: "Connect Spotify",
            description: "Link your Spotify account to access your saved shows and Spotify-exclusive podcasts alongside your RSS subscriptions.",
            accentColor: .green,
            gradient: [.green, .teal]
        ),
    ]

    var body: some View {
        ZStack {
            // Background gradient that animates with page
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
                .frame(height: 420)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: currentPage == index ? 10 : 7,
                                   height: currentPage == index ? 10 : 7)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 24)

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

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let gradient: [Color]
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52))
                    .foregroundColor(.white)
            }

            // Text
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
}

// MARK: - Onboarding Gate (wraps ContentView)
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
