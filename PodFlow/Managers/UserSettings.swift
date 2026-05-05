import SwiftUI
import Combine

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("colorSchemePreference") var colorSchemePreference: String = "system"
    @AppStorage("playbackSpeed") var playbackSpeed: Double = 1.0
    @AppStorage("trimSilence") var trimSilence: Bool = false
    @AppStorage("autoDownloadOnWifi") var autoDownloadOnWifi: Bool = true
    @AppStorage("skipForwardSeconds") var skipForwardSeconds: Int = 30
    @AppStorage("skipBackwardSeconds") var skipBackwardSeconds: Int = 15
    @AppStorage("sleepTimerMinutes") var sleepTimerMinutes: Int = 30
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("streamingQuality") var streamingQuality: String = "standard"
    @AppStorage("downloadQuality") var downloadQuality: String = "high"
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""

    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private init() {}
}


