import Foundation
import Combine

class SnipStore: ObservableObject {
    static let shared = SnipStore()

    @Published var snips: [Snip] = []

    // Private init enforces singleton usage
    private init() {
        loadSnips()
    }

    func add(_ snip: Snip) {
        snips.insert(snip, at: 0)
        saveSnips()
    }

    func delete(_ snip: Snip) {
        snips.removeAll { $0.id == snip.id }
        saveSnips()
    }

    func update(_ snip: Snip) {
        if let index = snips.firstIndex(where: { $0.id == snip.id }) {
            snips[index] = snip
            saveSnips()
        }
    }

    func snips(for episodeId: String) -> [Snip] {
        snips.filter { $0.episodeId == episodeId }
    }

    private func saveSnips() {
        if let data = try? JSONEncoder().encode(snips) {
            UserDefaults.standard.set(data, forKey: "savedSnips")
        }
    }

    private func loadSnips() {
        if let data = UserDefaults.standard.data(forKey: "savedSnips"),
           let decoded = try? JSONDecoder().decode([Snip].self, from: data) {
            snips = decoded
        }
    }
}
