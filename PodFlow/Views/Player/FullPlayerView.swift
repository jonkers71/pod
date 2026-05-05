import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showTranscript: Bool = false
    @State private var showChapters: Bool = false
    @State private var showSleepTimer: Bool = false
    @State private var showSpeedPicker: Bool = false
    @State private var showSnipCreator: Bool = false
    @State private var isDraggingSlider: Bool = false
    @State private var sliderValue: Double = 0

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadPlayerLayout
        } else {
            iPhonePlayerLayout
        }
    }

    // MARK: - iPhone Layout (vertical)
    private var iPhonePlayerLayout: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    artworkSection
                        .padding(.top, 8)
                    episodeInfoSection
                    progressSection
                    mainControlsSection
                    secondaryControlsSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showSnipCreator = true } label: {
                            Label("Create Snip", systemImage: "scissors")
                        }
                        Button { showTranscript = true } label: {
                            Label("View Transcript", systemImage: "text.alignleft")
                        }
                        Button { showChapters = true } label: {
                            Label("Chapters", systemImage: "list.number")
                        }
                        Button {} label: {
                            Label("Share Episode", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showTranscript) {
                TranscriptView()
            }
            .sheet(isPresented: $showSnipCreator) {
                SnipCreatorView()
            }
        }
    }

    // MARK: - iPad Layout (side-by-side)
    private var iPadPlayerLayout: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: Artwork + Info
                VStack(spacing: 24) {
                    artworkSection
                    episodeInfoSection
                    Spacer()
                }
                .frame(maxWidth: 380)
                .padding(32)

                Divider()

                // Right: Controls + Transcript
                ScrollView {
                    VStack(spacing: 24) {
                        progressSection
                        mainControlsSection
                        secondaryControlsSection
                        if showTranscript {
                            TranscriptInlineView()
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down").foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showTranscript.toggle() } label: {
                            Label("Transcript", systemImage: "text.alignleft")
                                .foregroundColor(showTranscript ? Color.accentTeal : .primary)
                        }
                        Button { showSnipCreator = true } label: {
                            Label("Snip", systemImage: "scissors")
                                .foregroundColor(Color.accentOrange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSnipCreator) {
                SnipCreatorView()
            }
        }
    }

    // MARK: - Artwork
    private var artworkSection: some View {
        Group {
            if let episode = audioPlayerManager.currentEpisode {
                AsyncImage(url: URL(string: episode.podcastImageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBackground.opacity(0.7))
                        .overlay(
                            Image(systemName: "mic.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                .scaleEffect(audioPlayerManager.isPlaying ? 1.0 : 0.92)
                .animation(.spring(response: 0.4), value: audioPlayerManager.isPlaying)
            }
        }
        .frame(maxWidth: 320, maxHeight: 320)
    }

    // MARK: - Episode Info
    private var episodeInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let episode = audioPlayerManager.currentEpisode {
                    Text(episode.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    Text(episode.podcastTitle)
                        .font(.subheadline)
                        .foregroundColor(Color.accentTeal)
                }
            }
            Spacer()
            Button {
                // Add to favourites
            } label: {
                Image(systemName: "heart")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Progress Slider
    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isDraggingSlider ? sliderValue : audioPlayerManager.progress },
                    set: { newValue in
                        sliderValue = newValue
                        isDraggingSlider = true
                    }
                ),
                in: 0...1
            ) { editing in
                isDraggingSlider = editing
                if !editing {
                    audioPlayerManager.seekTo(time: sliderValue * audioPlayerManager.duration)
                }
            }
            .accentColor(Color.accentTeal)

            HStack {
                Text(formatTime(audioPlayerManager.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Spacer()
                Text("-\(formatTime(audioPlayerManager.remainingTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Main Controls
    private var mainControlsSection: some View {
        HStack(spacing: 40) {
            Button {
                audioPlayerManager.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }

            Button {
                audioPlayerManager.seek(by: -15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title)
                    .foregroundColor(.primary)
            }

            Button {
                audioPlayerManager.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentTeal)
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.accentTeal.opacity(0.4), radius: 12, x: 0, y: 6)
                    Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }

            Button {
                audioPlayerManager.seek(by: 30)
            } label: {
                Image(systemName: "goforward.30")
                    .font(.title)
                    .foregroundColor(.primary)
            }

            Button {
                audioPlayerManager.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Secondary Controls
    private var secondaryControlsSection: some View {
        HStack(spacing: 0) {
            // Speed
            Button {
                showSpeedPicker = true
            } label: {
                Text("\(String(format: "%.1f", audioPlayerManager.playbackSpeed))×")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(minWidth: 44)
            }
            .confirmationDialog("Playback Speed", isPresented: $showSpeedPicker) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0], id: \.self) { speed in
                    Button("\(String(format: speed == 1.0 ? "%.0f" : "%.2g", speed))×") {
                        audioPlayerManager.setSpeed(Float(speed))
                    }
                }
            }

            Spacer()

            // Sleep Timer
            Button {
                showSleepTimer = true
            } label: {
                Image(systemName: audioPlayerManager.isSleepTimerActive ? "moon.fill" : "moon")
                    .font(.title3)
                    .foregroundColor(audioPlayerManager.isSleepTimerActive ? Color.accentTeal : .primary)
            }
            .confirmationDialog("Sleep Timer", isPresented: $showSleepTimer) {
                Button("5 minutes") { audioPlayerManager.startSleepTimer(minutes: 5) }
                Button("15 minutes") { audioPlayerManager.startSleepTimer(minutes: 15) }
                Button("30 minutes") { audioPlayerManager.startSleepTimer(minutes: 30) }
                Button("45 minutes") { audioPlayerManager.startSleepTimer(minutes: 45) }
                Button("1 hour") { audioPlayerManager.startSleepTimer(minutes: 60) }
                Button("End of episode") { audioPlayerManager.startSleepTimer(minutes: 9999) }
                if audioPlayerManager.isSleepTimerActive {
                    Button("Cancel Timer", role: .destructive) { audioPlayerManager.cancelSleepTimer() }
                }
            }

            Spacer()

            // Share
            Button {
                shareEpisode()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            // Snip
            Button {
                showSnipCreator = true
            } label: {
                Image(systemName: "scissors")
                    .font(.title3)
                    .foregroundColor(Color.accentOrange)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func shareEpisode() {
        guard let episode = audioPlayerManager.currentEpisode else { return }
        let text = "Listening to \"\(episode.title)\" on \(episode.podcastTitle) via PodFlow"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Transcript Inline (iPad)
struct TranscriptInlineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.headline)
            Text("Transcript will appear here once the episode has loaded. Tap any line to jump to that moment in the audio.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
