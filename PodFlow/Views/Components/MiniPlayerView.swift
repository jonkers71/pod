import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @Binding var showFullPlayer: Bool

    var body: some View {
        guard let episode = audioPlayerManager.currentEpisode else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 2)
                        Rectangle()
                            .fill(Color("AccentBlue"))
                            .frame(width: geo.size.width * audioPlayerManager.progress, height: 2)
                    }
                }
                .frame(height: 2)

                HStack(spacing: 12) {
                    // Artwork
                    AsyncImage(url: URL(string: episode.podcastImageURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray4))
                            .overlay(Image(systemName: "mic.fill").foregroundColor(.gray))
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Title
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text(episode.podcastTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: 20) {
                        Button {
                            audioPlayerManager.seek(by: -15)
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }

                        Button {
                            audioPlayerManager.togglePlayPause()
                        } label: {
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }

                        Button {
                            audioPlayerManager.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: -2)
            .onTapGesture { showFullPlayer = true }
        )
    }
}
