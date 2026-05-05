# PodFlow 🎙

**The smarter podcast app.** Built with SwiftUI for iPhone and iPad.

---

## Features

- **Discover & Search** — Browse trending podcasts via the Podcast Index API (4.5M+ shows)
- **Offline Downloads** — Download any episode for offline listening via background URLSession
- **AI Transcripts** — Interactive, scrolling transcripts with speaker identification
- **Snip & Save** — Save audio clips with transcript + AI summary in one tap
- **Export Insights** — Export snips to Notion, Obsidian, Readwise, or share as Markdown
- **Spotify Integration** — Link your Spotify account to access saved shows
- **Smart Player** — Variable speed, silence trimming, sleep timer, CarPlay, Apple Watch
- **Adaptive Layout** — Tab bar on iPhone; sidebar + split view on iPad
- **Monetisation** — Free (with ads) / Premium subscription / Lifetime purchase tiers
- **Onboarding** — Animated 5-page onboarding flow
- **Dark Mode** — True black OLED dark mode + bright light mode

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | SwiftUI |
| Architecture | MVVM |
| Audio Engine | AVFoundation (AVPlayer) |
| Downloads | URLSession (Background) |
| Persistence | UserDefaults + FileManager |
| Podcast Catalog | Podcast Index API |
| Streaming Platform | Spotify Web API (OAuth) |
| Min iOS Version | iOS 17.0 |

---

## Setup

1. Open `PodFlow.xcodeproj` in Xcode 15+
2. Set your **Bundle Identifier** and **Development Team** in Signing & Capabilities
3. Add your API keys:
   - `PodcastIndexService.swift` → `apiKey` + `apiSecret` from [api.podcastindex.org](https://api.podcastindex.org)
   - `SpotifyAuthService.swift` → `clientId` from [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
4. Build and run on a device or simulator (iOS 17+)

---

## Project Structure

```
PodFlow/
├── App/
│   └── PodFlowApp.swift          # App entry point
├── Models/
│   └── Models.swift              # All data models
├── Managers/
│   ├── AudioPlayerManager.swift  # AVPlayer engine + lock screen controls
│   ├── DownloadManager.swift     # Background downloads + file management
│   ├── UserSettings.swift        # App preferences + subscription state
│   └── SnipStore.swift           # Persisted snips storage
├── Services/
│   ├── PodcastIndexService.swift # Podcast Index API client
│   ├── SpotifyAuthService.swift  # Spotify OAuth + Web API
│   └── AIService.swift           # Transcript parsing + AI summaries
├── Views/
│   ├── ContentView.swift         # Root: iPhone tab bar / iPad sidebar
│   ├── Discover/                 # Discover + Podcast Detail views
│   ├── Search/                   # Search view
│   ├── Library/                  # Library + Downloads + Snips views
│   ├── Player/                   # Full player + Transcript + Snip creator
│   ├── Profile/                  # Profile + Settings + Paywall
│   ├── Onboarding/               # 5-page onboarding flow
│   └── Components/               # Mini player + shared components
├── Extensions/
│   └── ViewExtensions.swift      # Shimmer, haptics, colour helpers
└── Resources/
    └── Assets.xcassets/          # Colour sets + app icon
```

---

## Monetisation

| Tier | Price | Features |
|---|---|---|
| Free | $0 | Basic listening, 5 snips/month, banner ads |
| Premium | $4.99/mo or $39.99/yr | Ad-free, unlimited AI, cloud sync |
| Lifetime | $149.99 one-time | All features forever |

---

## TestFlight

See `TestFlight_Submission_Guide.md` in the root of this repository for step-by-step instructions on building, uploading, and distributing via TestFlight.

---

## Licence

MIT Licence. See `LICENSE` for details.
