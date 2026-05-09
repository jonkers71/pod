import Foundation
import AuthenticationServices
import Combine

class SpotifyAuthService: ObservableObject {
    static let shared = SpotifyAuthService()

    // MARK: - Spotify App Credentials
    // Register your app at https://developer.spotify.com/dashboard
    private let clientId = "daee12508f8b4f05abf09ab429ea504c"
    private let redirectURI = "podflow://spotify-callback"
    private let scopes = "user-library-read user-follow-read user-read-playback-state"

    @Published var isAuthenticated: Bool = false
    @Published var spotifyUser: SpotifyUser?
    @Published var savedShows: [SpotifyShow] = []
    @Published var isLoading: Bool = false

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    private var authSession: ASWebAuthenticationSession?

    private init() {
        loadTokens()
    }

    // MARK: - OAuth Flow
    func authenticate(presentationContext: ASWebAuthenticationPresentationContextProviding) {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "show_dialog", value: "true")
        ]

        guard let authURL = components.url else { return }

        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "podflow"
        ) { [weak self] callbackURL, error in
            guard let self = self, let callbackURL = callbackURL, error == nil else { return }
            self.handleCallbackURL(callbackURL)
        }
        authSession?.presentationContextProvider = presentationContext
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    func handleCallbackURL(_ url: URL) {
        guard url.scheme == "podflow",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { return }

        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)&client_id=\(clientId)"
        request.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            if let tokenResponse = try? JSONDecoder().decode(SpotifyTokenResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.accessToken = tokenResponse.accessToken
                    self.refreshToken = tokenResponse.refreshToken
                    self.tokenExpiryDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
                    self.isAuthenticated = true
                    self.saveTokens()
                    Task { await self.fetchCurrentUser() }
                }
            }
        }.resume()
    }

    // MARK: - API Calls
    func fetchCurrentUser() async {
        guard let token = validToken() else { return }
        guard let url = URL(string: "https://api.spotify.com/v1/me") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let user = try? JSONDecoder().decode(SpotifyUser.self, from: data) {
            await MainActor.run { self.spotifyUser = user }
        }
    }

    func fetchSavedShows() async {
        guard let token = validToken() else { return }
        guard let url = URL(string: "https://api.spotify.com/v1/me/shows?limit=50") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        await MainActor.run { isLoading = true }

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let response = try? JSONDecoder().decode(SpotifyShowsResponse.self, from: data) {
            let shows = response.items.map { $0.show }
            await MainActor.run {
                self.savedShows = shows
                self.isLoading = false
            }
        }
    }

    func searchShows(query: String) async throws -> [SpotifyShow] {
        guard let token = validToken() else { return [] }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encoded)&type=show&limit=20") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return response.shows?.items ?? []
    }

    func fetchShowEpisodes(showId: String) async throws -> [SpotifyEpisode] {
        guard let token = validToken() else { return [] }
        guard let url = URL(string: "https://api.spotify.com/v1/shows/\(showId)/episodes?limit=50&market=US") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SpotifyEpisodesResponse.self, from: data)
        return response.items ?? []
    }

    // MARK: - Token Management
    private func validToken() -> String? {
        guard let token = accessToken else { return nil }
        if let expiry = tokenExpiryDate, expiry > Date() {
            return token
        }
        // Token expired — refresh needed
        return nil
    }

    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        isAuthenticated = false
        spotifyUser = nil
        savedShows = []
        UserDefaults.standard.removeObject(forKey: "spotifyAccessToken")
        UserDefaults.standard.removeObject(forKey: "spotifyRefreshToken")
    }

    private func saveTokens() {
        UserDefaults.standard.set(accessToken, forKey: "spotifyAccessToken")
        UserDefaults.standard.set(refreshToken, forKey: "spotifyRefreshToken")
        UserDefaults.standard.set(tokenExpiryDate, forKey: "spotifyTokenExpiry")
    }

    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: "spotifyAccessToken")
        refreshToken = UserDefaults.standard.string(forKey: "spotifyRefreshToken")
        tokenExpiryDate = UserDefaults.standard.object(forKey: "spotifyTokenExpiry") as? Date
        isAuthenticated = accessToken != nil
    }
}

// MARK: - Spotify Response Models
struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

struct SpotifyUser: Codable {
    let id: String
    let displayName: String?
    let email: String?
    let images: [SpotifyImage]?

    var imageURL: String? { images?.first?.url }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email, images
    }
}

struct SpotifyShowsResponse: Codable {
    let items: [SpotifyShowItem]
}

struct SpotifyShowItem: Codable {
    let show: SpotifyShow
}

struct SpotifySearchResponse: Codable {
    let shows: SpotifyShowResults?
}

struct SpotifyShowResults: Codable {
    let items: [SpotifyShow]
}

struct SpotifyEpisodesResponse: Codable {
    let items: [SpotifyEpisode]?
}
