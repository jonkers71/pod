import Foundation

class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Transcript Fetching
    // Fetches transcript from Podcasting 2.0 transcriptUrl if available
    func fetchTranscript(from url: String) async throws -> [TranscriptSegment] {
        guard let transcriptURL = URL(string: url) else { throw AIError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: transcriptURL)

        // Try JSON format first (Podcasting 2.0 standard)
        if let jsonTranscript = try? JSONDecoder().decode(JSONTranscript.self, from: data) {
            return jsonTranscript.segments.enumerated().map { index, seg in
                TranscriptSegment(
                    id: "\(index)",
                    speaker: seg.speaker,
                    text: seg.body,
                    startTime: seg.startTime,
                    endTime: seg.endTime ?? (seg.startTime + 5)
                )
            }
        }

        // Try SRT format
        if let srtString = String(data: data, encoding: .utf8) {
            return parseSRT(srtString)
        }

        throw AIError.unsupportedFormat
    }

    // MARK: - AI Summary Generation (using OpenAI-compatible API)
    func generateEpisodeSummary(title: String, description: String) async -> String {
        // In production, call your AI API here
        // Using a template-based summary for the demo
        let cleaned = description
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let truncated = String(cleaned.prefix(500))
        return "**\(title)** — \(truncated.isEmpty ? "No description available." : truncated + "...")"
    }

    // MARK: - Snip Summary
    func generateSnipSummary(transcript: String) async -> String {
        // In production, send transcript to AI for a 1-2 sentence summary
        let words = transcript.split(separator: " ").prefix(30).joined(separator: " ")
        return words + (transcript.split(separator: " ").count > 30 ? "..." : "")
    }

    // MARK: - Auto Chapter Generation
    func generateChapters(from transcript: [TranscriptSegment]) -> [ChapterMarker] {
        // Simple heuristic: create a chapter every ~10 minutes
        var chapters: [ChapterMarker] = []
        let chapterInterval: TimeInterval = 600 // 10 minutes

        var nextChapterTime: TimeInterval = 0
        var chapterIndex = 0

        for segment in transcript {
            if segment.startTime >= nextChapterTime {
                let chapter = ChapterMarker(
                    id: "ch_\(chapterIndex)",
                    title: "Chapter \(chapterIndex + 1)",
                    startTime: segment.startTime,
                    endTime: nil
                )
                chapters.append(chapter)
                nextChapterTime = segment.startTime + chapterInterval
                chapterIndex += 1
            }
        }
        return chapters
    }

    // MARK: - Create Snip
    func createSnip(
        episode: Episode,
        startTime: TimeInterval,
        endTime: TimeInterval,
        transcript: [TranscriptSegment]
    ) async -> Snip {
        let relevantText = transcript
            .filter { $0.startTime >= startTime && $0.endTime <= endTime }
            .map { $0.text }
            .joined(separator: " ")

        let summary = await generateSnipSummary(transcript: relevantText)

        return Snip(
            id: UUID().uuidString,
            episodeId: episode.id,
            episodeTitle: episode.title,
            podcastTitle: episode.podcastTitle,
            podcastImageURL: episode.podcastImageURL,
            startTime: startTime,
            endTime: endTime,
            text: relevantText,
            summary: summary,
            createdAt: Date()
        )
    }

    // MARK: - SRT Parser
    private func parseSRT(_ srt: String) -> [TranscriptSegment] {
        var segments: [TranscriptSegment] = []
        let blocks = srt.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }

            let timeLine = lines[1]
            let text = lines[2...].joined(separator: " ")
            let times = timeLine.components(separatedBy: " --> ")

            if times.count == 2,
               let start = parseSRTTime(times[0]),
               let end = parseSRTTime(times[1]) {
                segments.append(TranscriptSegment(
                    id: UUID().uuidString,
                    speaker: nil,
                    text: text,
                    startTime: start,
                    endTime: end
                ))
            }
        }
        return segments
    }

    private func parseSRTTime(_ timeString: String) -> TimeInterval? {
        let parts = timeString.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
            .components(separatedBy: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }

    enum AIError: Error {
        case invalidURL
        case unsupportedFormat
        case apiError(String)
    }
}

// MARK: - JSON Transcript Format (Podcasting 2.0)
struct JSONTranscript: Codable {
    let version: String?
    let segments: [JSONTranscriptSegment]
}

struct JSONTranscriptSegment: Codable {
    let speaker: String?
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let body: String

    enum CodingKeys: String, CodingKey {
        case speaker
        case startTime = "startTime"
        case endTime = "endTime"
        case body
    }
}
