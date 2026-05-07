import SwiftUI

struct SnipsView: View {
    // Use EnvironmentObject so this shares the same SnipStore instance
    // that SnipCreatorView writes to. Previously @StateObject created a
    // separate instance, so saved snips never appeared here.
    @EnvironmentObject var snipStore: SnipStore
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var searchText: String = ""
    @State private var showExportSheet: Bool = false

    var filteredSnips: [Snip] {
        guard !searchText.isEmpty else { return snipStore.snips }
        return snipStore.snips.filter {
            $0.episodeTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if snipStore.snips.isEmpty {
                    emptyState
                } else {
                    snipsList
                }
            }
            .navigationTitle("My Snips")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search snips…")
            .toolbar {
                if !snipStore.snips.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showExportSheet = true } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color.accentTeal)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSnipsView(snips: snipStore.snips)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "scissors")
                .font(.system(size: 64))
                .foregroundColor(Color.accentOrange)
            Text("No Snips Yet")
                .font(.title2).fontWeight(.semibold)
            VStack(spacing: 8) {
                Text("While listening, tap the ✂️ button on the player to save a clip.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text("Each snip saves the timestamp, transcript text, and an AI summary.")
                    .font(.caption).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }

    // MARK: - Snips List
    private var snipsList: some View {
        List {
            ForEach(filteredSnips) { snip in
                SnipRowView(snip: snip)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            snipStore.delete(snip)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button { shareSnip(snip) } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(Color.accentTeal)
                    }
            }
            Spacer(minLength: 80).listRowBackground(Color.clear)
        }
        .listStyle(.plain).scrollContentBackground(.hidden).background(Color.appBackground)
    }

    private func shareSnip(_ snip: Snip) {
        let text = """
        🎙 \(snip.podcastTitle)
        📌 \(snip.episodeTitle)
        ⏱ \(formatTime(snip.startTime)) – \(formatTime(snip.endTime))

        "\(snip.text)"

        Shared via PodFlow
        """
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Snip Row
struct SnipRowView: View {
    let snip: Snip

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: snip.podcastImageURL)) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6).fill(Color.appBackground.opacity(0.7))
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(snip.podcastTitle).font(.caption).foregroundColor(.secondary).lineLimit(1)
                    Text(snip.episodeTitle).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                Text(formatDuration(snip.duration))
                    .font(.caption2).fontWeight(.semibold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.accentOrange.opacity(0.15))
                    .foregroundColor(Color.accentOrange)
                    .clipShape(Capsule())
            }

            if !snip.text.isEmpty {
                Text("\u{201C}\(snip.text)\u{201D}")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .italic()
            }

            if !snip.note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "note.text").font(.caption).foregroundColor(.secondary)
                    Text(snip.note).font(.caption).foregroundColor(.secondary).lineLimit(2)
                }
            }

            HStack {
                Text(snip.createdAt, style: .relative)
                    .font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text("\(formatTime(snip.startTime)) – \(formatTime(snip.endTime))")
                    .font(.caption2).monospacedDigit().foregroundColor(.secondary)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        return t < 60 ? "\(Int(t))s" : "\(Int(t/60))m \(Int(t) % 60)s"
    }
}

// MARK: - Export Snips
struct ExportSnipsView: View {
    let snips: [Snip]
    @Environment(\.dismiss) var dismiss

    var markdownExport: String {
        snips.map { snip in
            """
            ## \(snip.episodeTitle)
            **Podcast:** \(snip.podcastTitle)
            **Time:** \(formatTime(snip.startTime)) – \(formatTime(snip.endTime))

            > \(snip.text)

            \(snip.note.isEmpty ? "" : "**Note:** \(snip.note)\n")
            ---
            """
        }.joined(separator: "\n\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export \(snips.count) snip\(snips.count == 1 ? "" : "s") as Markdown")
                        .font(.headline).padding(.horizontal)

                    Text(markdownExport)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                    Button {
                        let av = UIActivityViewController(activityItems: [markdownExport], applicationActivities: nil)
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = scene.windows.first {
                            window.rootViewController?.present(av, animated: true)
                        }
                    } label: {
                        Label("Share / Export", systemImage: "square.and.arrow.up")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.accentTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Export Snips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
