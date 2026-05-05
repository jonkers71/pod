import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()

    // MARK: - Published State
    @Published var currentEpisode: Episode?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackSpeed: Float = 1.0
    @Published var isBuffering: Bool = false
    @Published var queue: [Episode] = []
    @Published var currentQueueIndex: Int = 0
    @Published var sleepTimerRemaining: TimeInterval? = nil
    @Published var isSleepTimerActive: Bool = false
    @Published var trimSilence: Bool = false

    // MARK: - Private
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var sleepTimer: Timer?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Remote Command Center (Lock Screen / CarPlay)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                self?.seek(by: event.interval)
            }
            return .success
        }
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let event = event as? MPSkipIntervalCommandEvent {
                self?.seek(by: -event.interval)
            }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
    }

    // MARK: - Playback Controls
    func load(episode: Episode, autoPlay: Bool = true) {
        // Save position for current episode
        saveCurrentPosition()

        currentEpisode = episode
        currentTime = episode.playbackPosition

        let url: URL
        if episode.isDownloaded, let localPath = episode.localFilePath,
           let localURL = URL(string: localPath) {
            url = localURL
        } else {
            guard let remoteURL = URL(string: episode.audioURL) else { return }
            url = remoteURL
        }

        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)

        // Observe buffering
        bufferObserver = playerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp && item.status == .readyToPlay
            }
        }

        statusObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    self?.duration = item.asset.duration.seconds
                    if let savedPosition = self?.currentEpisode?.playbackPosition, savedPosition > 0 {
                        self?.seekTo(time: savedPosition)
                    }
                }
            }
        }

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        player?.rate = playbackSpeed
        setupTimeObserver()
        updateNowPlayingInfo()

        // Observe end of episode
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(episodeDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        if autoPlay { play() }
    }

    func play() {
        player?.play()
        player?.rate = playbackSpeed
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        saveCurrentPosition()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(by seconds: TimeInterval) {
        let newTime = max(0, currentTime + seconds)
        seekTo(time: newTime)
    }

    func seekTo(time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = time
            }
        }
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying { player?.rate = speed }
    }

    func playNext() {
        guard currentQueueIndex < queue.count - 1 else { return }
        currentQueueIndex += 1
        load(episode: queue[currentQueueIndex])
    }

    func playPrevious() {
        if currentTime > 5 {
            seekTo(time: 0)
        } else if currentQueueIndex > 0 {
            currentQueueIndex -= 1
            load(episode: queue[currentQueueIndex])
        }
    }

    func addToQueue(_ episode: Episode) {
        if !queue.contains(where: { $0.id == episode.id }) {
            queue.append(episode)
        }
    }

    func addToQueueNext(_ episode: Episode) {
        queue.insert(episode, at: currentQueueIndex + 1)
    }

    func removeFromQueue(at index: Int) {
        guard index < queue.count else { return }
        queue.remove(at: index)
    }

    // MARK: - Sleep Timer
    func startSleepTimer(minutes: Int) {
        sleepTimer?.invalidate()
        sleepTimerRemaining = TimeInterval(minutes * 60)
        isSleepTimerActive = true

        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let remaining = self.sleepTimerRemaining {
                if remaining <= 0 {
                    self.pause()
                    self.cancelSleepTimer()
                } else {
                    self.sleepTimerRemaining = remaining - 1
                }
            }
        }
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = nil
        isSleepTimerActive = false
    }

    // MARK: - Time Observer
    private func setupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        guard let episode = currentEpisode else { return }
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = episode.title
        info[MPMediaItemPropertyArtist] = episode.podcastTitle
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Position Persistence
    private func saveCurrentPosition() {
        guard let episode = currentEpisode else { return }
        var savedPositions = UserDefaults.standard.dictionary(forKey: "episodePositions") as? [String: Double] ?? [:]
        savedPositions[episode.id] = currentTime
        UserDefaults.standard.set(savedPositions, forKey: "episodePositions")
    }

    func getSavedPosition(for episodeId: String) -> TimeInterval {
        let positions = UserDefaults.standard.dictionary(forKey: "episodePositions") as? [String: Double] ?? [:]
        return positions[episodeId] ?? 0
    }

    // MARK: - Episode Finish
    @objc private func episodeDidFinish() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            if self.currentQueueIndex < self.queue.count - 1 {
                self.playNext()
            }
        }
    }

    // MARK: - Progress
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: TimeInterval {
        return duration - currentTime
    }
}
