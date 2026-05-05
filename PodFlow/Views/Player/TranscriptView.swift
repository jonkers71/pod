import SwiftUI

struct TranscriptView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var segments: [TranscriptSegment] = []
    @State private var isLoading: Bool = true
    @State private var searchText: String = ""
    @State private var autoScroll: Bool = true

    var filteredSegments: [TranscriptSegment] {
        guard !searchText.isEmpty else { return segments }
        return segments.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !subscriptionManager.currentTier.hasUnlimitedAI {
                    premiumGate
                } else if isLoading {
                    loadingView
                } else if segments.isEmpty {
                    emptyView
                } else {
                    transcriptContent
                }
            }
            .navigationTitle("Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search transcript...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Auto-scroll", isOn: $autoScroll)
                        .toggleStyle(.button)
                        .font(.caption)
                }
            }
        }
        .task { await loadTranscript() }
    }

    // MARK: - Transcript Content
    private var transcriptContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredSegments) { segment in
                        TranscriptSegmentRow(
                            segment: segment,
                            isActive: isActiveSegment(segment)
                        )
                        .id(segment.id)
                        .onTapGesture {
                            audioPlayerManager.seekTo(time: segment.startTime)
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .onChange(of: audioPlayerManager.currentTime) { _, time in
                if autoScroll, let active = activeSegment {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(active.id, anchor: .center)
                    }
                }
            }
        }
    }

    private var activeSegment: TranscriptSegment? {
        segments.last { $0.startTime <= audioPlayerManager.currentTime }
    }

    private func isActiveSegment(_ segment: TranscriptSegment) -> Bool {
        segment.startTime <= audioPlayerManager.currentTime &&
        segment.endTime >= audioPlayerManager.currentTime
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading transcript…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty
    private var emptyView: some View {
        ContentUnavailableView(
            "No Transcript Available",
            systemImage: "text.alignleft",
            description: Text("This episode doesn't have a transcript yet. Transcripts are available for podcasts that support Podcasting 2.0.")
        )
    }

    // MARK: - Premium Gate
    private var premiumGate: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "text.alignleft")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentPurple"))
            Text("Transcripts are a Premium Feature")
                .font(.title3).fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text("Upgrade to PodFlow Premium to access full searchable transcripts, AI summaries, and unlimited snips.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            NavigationLink(destination: PaywallView()) {
                Text("Upgrade to Premium")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color("AccentBlue"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    // MARK: - Load Transcript
    private func loadTranscript() async {
        isLoading = true
        // Generate mock transcript for demo
        try? await Task.sleep(nanoseconds: 800_000_000)
        segments = generateMockTranscript()
        isLoading = false
    }

    private func generateMockTranscript() -> [TranscriptSegment] {
        let lines = [
            ("Host", "Welcome back to the show. Today we have a really fascinating guest joining us."),
            ("Host", "We're going to be talking about technology, innovation, and what the future holds."),
            ("Guest", "Thanks so much for having me. I'm really excited to be here today."),
            ("Host", "Let's start from the beginning. How did you first get into this field?"),
            ("Guest", "It was actually quite by accident. I was studying something completely different at university."),
            ("Guest", "But then I stumbled across this problem that I just couldn't stop thinking about."),
            ("Host", "That's fascinating. And what was that problem exactly?"),
            ("Guest", "It was about how we process information at scale. The challenge of making sense of massive datasets."),
            ("Host", "And how long did it take you to find a solution?"),
            ("Guest", "Years, honestly. There were so many dead ends along the way."),
            ("Host", "But you persisted. What kept you going?"),
            ("Guest", "The belief that if I could solve this, it would genuinely help people."),
            ("Host", "Let's talk about where things are heading. What excites you most about the next five years?"),
            ("Guest", "The convergence of AI and personalised experiences. We're just scratching the surface."),
            ("Host", "Any advice for people just starting out in this space?"),
            ("Guest", "Stay curious. Read widely. And don't be afraid to work on problems that seem too hard."),
        ]
        var time: TimeInterval = 0
        return lines.enumerated().map { index, line in
            let duration = TimeInterval(Double(line.1.split(separator: " ").count) * 0.45)
            let seg = TranscriptSegment(id: "\(index)", speaker: line.0, text: line.1, startTime: time, endTime: time + duration)
            time += duration + 0.3
            return seg
        }
    }
}

// MARK: - Transcript Segment Row
struct TranscriptSegmentRow: View {
    let segment: TranscriptSegment
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Timestamp
            Text(formatTime(segment.startTime))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isActive ? Color("AccentBlue") : .secondary)
                .frame(width: 44, alignment: .trailing)
                .padding(.top, 2)

            // Speaker + Text
            VStack(alignment: .leading, spacing: 2) {
                if let speaker = segment.speaker {
                    Text(speaker)
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(isActive ? Color("AccentBlue") : .secondary)
                        .textCase(.uppercase)
                }
                Text(segment.text)
                    .font(.subheadline)
                    .foregroundColor(isActive ? .primary : .secondary)
                    .fontWeight(isActive ? .medium : .regular)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isActive ? Color("AccentBlue").opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
