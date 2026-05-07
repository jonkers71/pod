import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @Binding var showFullPlayer: Bool

    var body: some View {
        guard let episode = audioPlayerManager.currentEpisode else {
            return AnyView(EmptyView())
        }
        return AnyView(content(episode: episode))
    }

    private func content(episode: Episode) -> some View {
        VStack(spacing: 0) {
            // Thin progress bar at the very top
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 2)
                    Rectangle()
                        .fill(Color.accentTeal)
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
                        .fill(Color.white.opacity(0.1))
                        .overlay(Image(systemName: "mic.fill").foregroundColor(.secondary))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.title)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                    Text(episode.podcastTitle)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: 18) {
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
                        ZStack {
                            Circle()
                                .fill(Color.accentTeal)
                                .frame(width: 38, height: 38)
                            Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
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
        // Glass material — works on iOS 17+ and looks even better on iOS 26 Liquid Glass
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
        .onTapGesture { showFullPlayer = true }
    }
}
