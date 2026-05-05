import SwiftUI

struct SnipCreatorView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var snipStore = SnipStore.shared
    @State private var startTime: TimeInterval
    @State private var endTime: TimeInterval
    @State private var note: String = ""
    @State private var isSaving: Bool = false
    @State private var savedSnip: Snip? = nil

    init() {
        let current = AudioPlayerManager.shared.currentTime
        _startTime = State(initialValue: max(0, current - 30))
        _endTime   = State(initialValue: current)
    }

    var snipDuration: TimeInterval { endTime - startTime }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Episode info
                    if let episode = audioPlayerManager.currentEpisode {
                        episodeHeader(episode)
                    }

                    // Time range selector
                    timeRangeSection

                    // Preview
                    previewSection

                    // Note field
                    noteSection

                    // Save button
                    saveButton

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Create Snip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Episode Header
    private func episodeHeader(_ episode: Episode) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: episode.podcastImageURL)) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8).fill(Color.appBackground.opacity(0.7))
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                Text(episode.podcastTitle).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Time Range
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Clip Range")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start").font(.caption).foregroundColor(.secondary)
                    Text(formatTime(startTime))
                        .font(.title3).fontWeight(.bold).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .center, spacing: 4) {
                    Text("Duration").font(.caption).foregroundColor(.secondary)
                    Text(formatTime(snipDuration))
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(Color.accentOrange).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("End").font(.caption).foregroundColor(.secondary)
                    Text(formatTime(endTime))
                        .font(.title3).fontWeight(.bold).monospacedDigit()
                }
            }

            // Start slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Start: \(formatTime(startTime))").font(.caption).foregroundColor(.secondary)
                Slider(value: $startTime, in: 0...max(audioPlayerManager.duration - 1, 1)) { _ in
                    if startTime >= endTime { endTime = min(startTime + 30, audioPlayerManager.duration) }
                }
                .accentColor(Color.accentTeal)
            }

            // End slider
            VStack(alignment: .leading, spacing: 4) {
                Text("End: \(formatTime(endTime))").font(.caption).foregroundColor(.secondary)
                Slider(value: $endTime, in: 0...max(audioPlayerManager.duration, 1)) { _ in
                    if endTime <= startTime { startTime = max(endTime - 30, 0) }
                }
                .accentColor(Color.accentOrange)
            }

            // Quick duration buttons
            HStack(spacing: 10) {
                ForEach([15, 30, 60, 120], id: \.self) { secs in
                    Button("\(secs)s") {
                        endTime = min(startTime + TimeInterval(secs), audioPlayerManager.duration)
                    }
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.appBackground.opacity(0.7))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Preview
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview").font(.headline)
            HStack(spacing: 16) {
                Button {
                    audioPlayerManager.seekTo(time: startTime)
                    audioPlayerManager.play()
                } label: {
                    Label("Play Snip", systemImage: "play.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.accentTeal)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Button {
                    audioPlayerManager.seekTo(time: startTime)
                } label: {
                    Label("Jump to Start", systemImage: "arrow.left.to.line")
                        .font(.subheadline)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.appBackground.opacity(0.7))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Note
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a Note (optional)").font(.headline)
            TextField("What's interesting about this moment?", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task { await saveSnip() }
        } label: {
            Group {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Label("Save Snip", systemImage: "scissors")
                        .font(.headline).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).padding()
            .background(Color.accentOrange)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSaving || snipDuration < 1)
    }

    // MARK: - Save
    private func saveSnip() async {
        guard let episode = audioPlayerManager.currentEpisode else { return }
        isSaving = true
        let snip = await AIService.shared.createSnip(
            episode: episode,
            startTime: startTime,
            endTime: endTime,
            transcript: []
        )
        var finalSnip = snip
        finalSnip.note = note
        snipStore.add(finalSnip)
        isSaving = false
        dismiss()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
