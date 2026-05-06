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
    private var tap: MTAudioProcessingTap?
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
                // Use allowBluetoothHFP (replaces deprecated allowBluetooth)
                options: [.allowBluetoothHFP, .allowAirPlay]
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
            self?.play(); return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            if let e = event as? MPSkipIntervalCommandEvent { self?.seek(by: e.interval) }
            return .success
        }
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            if let e = event as? MPSkipIntervalCommandEvent { self?.seek(by: -e.interval) }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext(); return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious(); return .success
        }
    }

    // MARK: - Load Episode
    func load(episode: Episode, autoPlay: Bool = true) {
        saveCurrentPosition()
        currentEpisode = episode
        currentTime = episode.playbackPosition

        let url: URL
        if episode.isDownloaded,
           let localPath = episode.localFilePath,
           let localURL = URL(string: localPath) {
            url = localURL
        } else {
            guard let remoteURL = URL(string: episode.audioURL) else { return }
            url = remoteURL
        }

        let asset = AVURLAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)

        bufferObserver = playerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp && item.status == .readyToPlay
            }
        }

        statusObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            // Use async load for duration (replaces deprecated .duration property)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    let dur = try await asset.load(.duration)
                    self.duration = dur.seconds.isFinite ? dur.seconds : 0
                    if self.currentEpisode?.playbackPosition ?? 0 > 0 {
                        self.seekTo(time: self.currentEpisode?.playbackPosition ?? 0)
                    }
                } catch {
                    print("Duration load error: \(error)")
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(episodeDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        setupAudioTap()
        if autoPlay { play() }
    }

    // MARK: - Playback Controls
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

    func togglePlayPause() { isPlaying ? pause() : play() }

    func seek(by seconds: TimeInterval) {
        seekTo(time: max(0, currentTime + seconds))
    }

    func seekTo(time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            DispatchQueue.main.async { self?.currentTime = time }
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
        if !queue.contains(where: { $0.id == episode.id }) { queue.append(episode) }
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
                if remaining <= 0 { self.pause(); self.cancelSleepTimer() }
                else { self.sleepTimerRemaining = remaining - 1 }
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
        if let observer = timeObserver { player?.removeTimeObserver(observer) }
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
        var positions = UserDefaults.standard.dictionary(forKey: "episodePositions") as? [String: Double] ?? [:]
        positions[episode.id] = currentTime
        UserDefaults.standard.set(positions, forKey: "episodePositions")
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
            if self.currentQueueIndex < self.queue.count - 1 { self.playNext() }
        }
    }

    // MARK: - Progress
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: TimeInterval { duration - currentTime }

    // MARK: - Smart Speed (Silence Trimming) — AVAudioProcessingTap infrastructure
    private func setupAudioTap() {
        guard let playerItem = playerItem else { return }

        // Use async loadTracks (replaces deprecated tracks(withMediaType:))
        Task {
            do {
                let tracks = try await playerItem.asset.loadTracks(withMediaType: .audio)
                guard let assetTrack = tracks.first else { return }

                var callbacks = MTAudioProcessingTapCallbacks(
                    version: kMTAudioProcessingTapCallbacksVersion_0,
                    clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                    init: { (tap, clientInfo, tapStorageOut) in tapStorageOut.pointee = clientInfo },
                    finalize: { _ in },
                    prepare: { _, _, _ in },
                    unprepare: { _ in },
                    process: { (tap, numberFrames, flags, bufferListPtr, numberFramesOut, flagsOut) in
                        let status = MTAudioProcessingTapGetSourceAudio(
                            tap, numberFrames, bufferListPtr, flagsOut, nil, numberFramesOut
                        )
                        if status != noErr { return }
                        // Silence detection logic placeholder:
                        // Analyse bufferListPtr amplitude here when trimSilence is true
                    }
                )

                var tap: MTAudioProcessingTap?
                let status = MTAudioProcessingTapCreate(
                    kCFAllocatorDefault, &callbacks,
                    kMTAudioProcessingTapCreationFlag_PostEffects, &tap
                )

                if status == noErr, let tap = tap {
                    let inputParams = AVMutableAudioMixInputParameters(track: assetTrack)
                    inputParams.audioTapProcessor = tap
                    let mix = AVMutableAudioMix()
                    mix.inputParameters = [inputParams]
                    await MainActor.run { playerItem.audioMix = mix }
                    self.tap = tap
                }
            } catch {
                print("AudioTap setup error: \(error)")
            }
        }
    }
}
