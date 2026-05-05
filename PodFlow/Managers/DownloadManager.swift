import Foundation
import Combine

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var downloadStates: [String: DownloadState] = [:]
    @Published var downloadedEpisodeIds: Set<String> = []

    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.podflow.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        loadDownloadedEpisodes()
    }

    // MARK: - Download Controls
    func download(episode: Episode) {
        guard !isDownloaded(episodeId: episode.id) else { return }
        guard let url = URL(string: episode.audioURL) else { return }

        downloadStates[episode.id] = .downloading(progress: 0)

        let task = urlSession.downloadTask(with: url)
        task.taskDescription = episode.id
        downloadTasks[episode.id] = task
        task.resume()
    }

    func cancelDownload(episodeId: String) {
        downloadTasks[episodeId]?.cancel()
        downloadTasks.removeValue(forKey: episodeId)
        downloadStates[episodeId] = .notDownloaded
    }

    func deleteDownload(episodeId: String) {
        let fileURL = localFileURL(for: episodeId)
        try? FileManager.default.removeItem(at: fileURL)
        downloadedEpisodeIds.remove(episodeId)
        downloadStates[episodeId] = .notDownloaded
        saveDownloadedEpisodes()
    }

    func isDownloaded(episodeId: String) -> Bool {
        return downloadedEpisodeIds.contains(episodeId)
    }

    func localFileURL(for episodeId: String) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("episodes").appendingPathComponent("\(episodeId).mp3")
    }

    func downloadState(for episodeId: String) -> DownloadState {
        return downloadStates[episodeId] ?? (isDownloaded(episodeId: episodeId) ? .downloaded : .notDownloaded)
    }

    var totalDownloadedSize: String {
        let episodesDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("episodes")
        guard let files = try? FileManager.default.contentsOfDirectory(at: episodesDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        let totalBytes = files.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.reduce(0, +)
        let mb = Double(totalBytes) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }

    // MARK: - Persistence
    private func saveDownloadedEpisodes() {
        UserDefaults.standard.set(Array(downloadedEpisodeIds), forKey: "downloadedEpisodeIds")
    }

    private func loadDownloadedEpisodes() {
        let ids = UserDefaults.standard.stringArray(forKey: "downloadedEpisodeIds") ?? []
        downloadedEpisodeIds = Set(ids)
        // Verify files still exist
        downloadedEpisodeIds = downloadedEpisodeIds.filter { id in
            FileManager.default.fileExists(atPath: localFileURL(for: id).path)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let episodeId = downloadTask.taskDescription else { return }

        let destinationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("episodes")

        try? FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let destination = destinationDir.appendingPathComponent("\(episodeId).mp3")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)

            DispatchQueue.main.async {
                self.downloadedEpisodeIds.insert(episodeId)
                self.downloadStates[episodeId] = .downloaded
                self.downloadTasks.removeValue(forKey: episodeId)
                self.saveDownloadedEpisodes()
            }
        } catch {
            DispatchQueue.main.async {
                self.downloadStates[episodeId] = .failed(error: error.localizedDescription)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let episodeId = downloadTask.taskDescription, totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadStates[episodeId] = .downloading(progress: progress)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let episodeId = task.taskDescription, let error = error else { return }
        DispatchQueue.main.async {
            self.downloadStates[episodeId] = .failed(error: error.localizedDescription)
            self.downloadTasks.removeValue(forKey: episodeId)
        }
    }
}
