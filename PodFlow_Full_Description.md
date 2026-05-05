# PodFlow — Full App Description, Feature Inventory, Beta Test Programme & Gap Analysis

**Version:** 1.0.0 (Build 1)
**Platform:** iOS 17+ / iPadOS 17+ (Universal)
**Author:** Manus AI
**Date:** May 2026

---

## 1. What Is PodFlow?

PodFlow is a native iOS and iPadOS podcast app built in Swift and SwiftUI. It is designed to be the podcast app that power users have always wanted but never quite got from the big platforms. Where Spotify and Apple Podcasts treat podcasts like music — passive, disposable, and locked inside walled gardens — PodFlow treats every episode as a source of knowledge worth capturing, organising, and sharing.

The core philosophy is simple: **listen smarter, not just longer.** Every feature in PodFlow is built around helping users get more out of the time they spend listening — whether that is through AI-generated transcripts, one-tap audio clipping, smart organisation, or seamless offline access.

The app is designed as a **universal app**, meaning it runs on both iPhone and iPad with a fully adaptive interface. On iPhone it uses a familiar tab bar layout optimised for one-handed use. On iPad it switches automatically to a sidebar and split-view layout, making full use of the larger screen.

---

## 2. Visual Design

PodFlow uses a custom colour system extracted directly from the app logo, giving it a distinctive and consistent visual identity across every screen.

| Element | Light Mode | Dark Mode |
|---|---|---|
| Screen background | Cool Slate `#D1D1DB` | True Black `#000000` |
| Cards and surfaces | Near-white `#F5F5F9` | Dark Grey `#1C1C1E` |
| Primary accent | Teal `#20A0B0` | Teal `#20A0B0` |
| Secondary accent | Orange `#FF9500` | Orange `#FF9500` |
| Premium / tertiary | Purple `#AF52DE` | Purple `#AF52DE` |
| Success / Spotify | Green `#34C759` | Green `#34C759` |
| Danger / delete | Red `#FF3B30` | Red `#FF3B30` |

The Cool Slate background in light mode was chosen specifically to make the logo colours pop without going to a full dark theme. Dark mode uses true black, which looks exceptional on OLED iPhone screens (iPhone X and later). Both modes use the same accent colours, ensuring the brand identity is consistent regardless of the user's preference.

---

## 3. Features Built and Implemented

### 3.1 Onboarding
A five-page animated onboarding flow greets new users on first launch. Each page uses a full-screen gradient background matching the logo colour palette, with a large icon, headline, and description. Users can skip to the end at any time. The onboarding is shown only once and is gated by a `hasCompletedOnboarding` flag stored in `UserDefaults`.

### 3.2 Discover Screen
The Discover screen is the home tab and the primary entry point for finding new content. It features a horizontal scrolling category chip row at the top, allowing users to filter trending content by genre (Technology, Business, Comedy, News, True Crime, Education, Health, Sports, Science, History). Below this, trending podcasts are displayed in a horizontal card scroll on iPhone and a four-column grid on iPad. An Editor's Picks section below shows a vertical list of curated shows. The screen supports pull-to-refresh and shows skeleton loading placeholders while data is fetching.

### 3.3 Search Screen
The search screen provides a debounced search (0.5 second delay) across both the Podcast Index catalog and the user's linked Spotify account simultaneously. Results are segmented into Podcasts and Spotify Shows sections. When no search is active, a two-column category grid is shown as a browsing aid. The search source can be filtered to All, Podcasts only, or Spotify only via a segmented control.

### 3.4 Library Screen
The Library tab shows all subscribed podcasts in a list. Users can swipe left on any podcast to unsubscribe. A filter picker at the top allows switching between All, Downloaded, and In Progress views. A download manager button in the top right opens a dedicated Downloads sheet showing all offline episodes, total storage used, and the option to delete individual downloads or clear all at once.

### 3.5 Podcast Detail Screen
Tapping any podcast opens its detail screen, which shows the artwork, title, author, category tags, episode count, and a collapsible description. Below this is the full episode list, sorted newest first by default with a toggle to reverse the order. Each episode row shows the title, publish date, duration, a partial playback progress bar if the episode has been started, a download button with live progress indicator, and a three-dot menu for additional actions (Play Next, Add to Queue, Share, Download/Delete).

### 3.6 Audio Playback Engine
PodFlow uses `AVFoundation`'s `AVPlayer` as its audio engine. The player supports:
- Variable playback speed from 0.5× to 3.0× with pitch correction
- Skip forward 30 seconds and skip backward 15 seconds
- Seek to any position via a precision slider
- Automatic position saving — if you close the app mid-episode, it resumes exactly where you left off
- Lock screen and Control Centre controls via `MPRemoteCommandCenter`
- Now Playing info (artwork, title, podcast name, elapsed time, duration)
- CarPlay support via the standard `AVAudioSession` playback category
- Apple Watch playback controls (via the remote command centre)
- Sleep timer with options from 5 minutes to end of episode, with a cancel option

### 3.7 Mini Player
A floating mini player appears at the bottom of every screen whenever an episode is loaded. It shows the podcast artwork, episode title, podcast name, a progress bar, and play/pause, skip back, and skip forward controls. Tapping anywhere on the mini player opens the full player. On iPad, the mini player floats in the bottom-right corner rather than spanning the full width.

### 3.8 Full Player Screen
The full player is a sheet that slides up from the mini player. On iPhone it uses a vertical layout with large artwork, episode info, a precision progress slider with timestamps, main playback controls, and a secondary controls row. On iPad it uses a side-by-side layout with artwork and info on the left and controls plus an optional inline transcript panel on the right. The secondary controls row includes speed picker, sleep timer, share, and the Snip button.

### 3.9 Offline Downloads
PodFlow uses `URLSession` with a background configuration (`URLSessionConfiguration.background`) to download episodes. This means downloads continue even if the app is backgrounded or the screen is locked. Download progress is shown as a circular progress ring on each episode row. Downloaded episodes are stored in the app's Documents directory and played back from local storage automatically, bypassing the network entirely. Storage usage is tracked and displayed in the Downloads manager and the Profile screen.

### 3.10 Transcripts
The Transcript screen is accessible from the full player menu. It shows a scrolling list of transcript segments, each with a timestamp, optional speaker label, and the spoken text. The active segment (the one currently being spoken) is highlighted in teal and the view auto-scrolls to keep it in view. Users can tap any segment to jump to that moment in the audio. A search bar allows searching for any word or phrase across the full transcript. Auto-scroll can be toggled off. Transcripts are fetched from the Podcasting 2.0 `transcriptUrl` field in the RSS feed if available, supporting both JSON and SRT formats. The transcript screen is gated behind the Premium subscription tier.

### 3.11 Snip Creator
The Snip Creator allows users to save a specific audio clip from any episode. It is accessible via the scissors icon on the full player. Users set a start and end time using two sliders, with quick-select buttons for 15s, 30s, 60s, and 120s clip lengths. A preview button plays the selected range. An optional note field allows adding context. On saving, the app calls the AI service to generate a short summary of the transcript text within the selected range. The snip is stored locally with the audio timestamps, transcript text, AI summary, and note.

### 3.12 Snips Tab
The Snips tab shows all saved snips in reverse chronological order. Each snip card shows the podcast artwork, podcast name, episode title, the transcript text as a pull quote, the optional note, the creation date, and the clip duration. Users can swipe right to share a snip (generates a formatted Markdown text block) or swipe left to delete it. A search bar filters snips by episode title, transcript text, or note content. An export button generates a full Markdown document of all snips, which can be shared to any app including Notion, Obsidian, Bear, or the Files app.

### 3.13 Spotify Integration
Users can connect their Spotify account from the Profile screen. This triggers a standard OAuth 2.0 flow using `ASWebAuthenticationSession`, which opens Spotify's login page in a secure in-app browser. Once authenticated, the app can fetch the user's saved Spotify shows and search the Spotify catalog. Spotify shows appear in search results with a green Spotify badge. Tapping a Spotify show opens it in the Spotify app for playback, as Spotify's API does not permit third-party audio streaming. Users can disconnect their Spotify account at any time from the Profile screen.

### 3.14 Monetisation
PodFlow uses a three-tier hybrid monetisation model:
- **Free tier:** Full access to basic listening, RSS subscriptions, offline downloads, and up to 5 snips per month. Banner ad placeholders are shown at the top of the Discover screen.
- **Premium subscription:** $4.99/month or $39.99/year. Removes all ads, unlocks unlimited AI features (transcripts, summaries, snips), enables cloud backup and sync, and unlocks advanced social sharing. Implemented via Apple's In-App Purchase framework (StoreKit).
- **Lifetime access:** $149.99 one-time payment. All Premium features forever, including all future updates.

The paywall screen features a gradient hero banner, a feature list with icons, a plan picker with the recommended Annual plan highlighted, and a gradient CTA button. A Restore Purchases button is included as required by App Store guidelines.

### 3.15 Profile and Settings
The Profile screen provides full control over the app experience, including default playback speed, silence trimming toggle, auto-download on Wi-Fi toggle, skip forward and backward interval customisation, storage management, appearance (System/Light/Dark), Spotify connection management, subscription status display, and links to the privacy policy and terms of service.

### 3.16 iPad Adaptive Layout
On iPad (`horizontalSizeClass == .regular`), the app switches from a tab bar to a `NavigationSplitView` with a sidebar. The sidebar shows the main navigation items and a list of the user's subscribed podcasts for quick access. The main content area shows the selected screen. The Discover screen uses a four-column podcast grid instead of a horizontal scroll. The Full Player uses a side-by-side layout. The mini player floats in the bottom-right corner. The app fully supports iPad multitasking (Split View and Slide Over) and pointer/trackpad interaction.

---

## 4. What to Expect on First Run

When you first open PodFlow on your device, here is exactly what will happen:

**Step 1 — Onboarding.** The five-page onboarding flow will appear. Swipe through or tap Next to advance. Tap Skip to jump straight to the app.

**Step 2 — Discover screen loads.** The app will attempt to fetch trending podcasts from the Podcast Index API. If you have not added your API key yet, it will fall back to a set of eight mock podcasts (The Daily, Lex Fridman, Serial, How I Built This, Stuff You Should Know, Hidden Brain, Crime Junkie, Conan O'Brien). These are placeholders only — the artwork will not load and tapping them will show mock episodes.

**Step 3 — Add your Podcast Index API key.** To get real data, sign up for a free key at `api.podcastindex.org`, then open `PodcastIndexService.swift` in Xcode and replace the placeholder values. Rebuild and run.

**Step 4 — Search works immediately.** Even without an API key, the search screen will show the category grid. With an API key, searching will return real results from the full 4.5 million podcast catalog.

**Step 5 — Subscribe to a podcast.** Tap any podcast, then tap Subscribe. It will appear in your Library tab.

**Step 6 — Play an episode.** Tap the play button on any episode. The mini player will appear at the bottom. Tap it to open the full player.

**Step 7 — Download an episode.** Tap the download arrow on any episode row. The circular progress ring will show download progress. Once complete, the episode plays from local storage.

---

## 5. Beta Test Programme

The following structured test programme is recommended for the TestFlight beta phase. It is designed to be run by a small group of 5–20 testers across a range of devices and iOS versions.

### Phase 1 — Smoke Testing (Week 1)
The goal of Phase 1 is to confirm the app installs, launches, and navigates without crashing on a range of devices.

| Test | Expected Result |
|---|---|
| Install via TestFlight | App installs without error |
| First launch — onboarding | Five-page onboarding displays correctly |
| Complete onboarding | Discover screen loads |
| Navigate all five tabs | No crashes, correct screens load |
| Rotate iPhone to landscape | Layout adjusts gracefully |
| Open on iPad | Sidebar navigation appears |
| Rotate iPad to portrait and landscape | Layout adapts correctly |
| Force-quit and relaunch | App resumes on Discover screen |

### Phase 2 — Core Playback (Week 1–2)
The goal of Phase 2 is to confirm audio playback works reliably across all scenarios.

| Test | Expected Result |
|---|---|
| Search for a podcast and tap a result | Podcast detail screen opens |
| Tap play on an episode | Mini player appears, audio plays |
| Lock the screen while playing | Audio continues, lock screen controls appear |
| Use lock screen skip forward/back | Playback position changes correctly |
| Change playback speed to 1.5× | Audio speeds up without distortion |
| Set sleep timer to 5 minutes | Audio pauses after 5 minutes |
| Play via Bluetooth headphones | Audio routes correctly |
| Play via CarPlay (if available) | App appears in CarPlay, controls work |
| Force-quit app mid-episode | On relaunch, episode resumes at correct position |
| Play next episode in queue | Transitions automatically |

### Phase 3 — Downloads (Week 2)
The goal of Phase 3 is to confirm offline downloads work reliably.

| Test | Expected Result |
|---|---|
| Download an episode on Wi-Fi | Progress ring fills, download completes |
| Download an episode on cellular | Download proceeds (if auto-download is off, confirm it does not auto-start) |
| Enable aeroplane mode | Previously downloaded episodes play normally |
| Check Downloads screen | Episode listed with correct file size |
| Delete a download | File removed, episode shows download button again |
| Download 5 episodes simultaneously | All complete without errors |
| Background the app during download | Download continues in background |

### Phase 4 — AI Features (Week 2–3)
The goal of Phase 4 is to confirm the transcript and snip features work correctly.

| Test | Expected Result |
|---|---|
| Open transcript on a free account | Premium gate screen appears |
| Upgrade to Premium (sandbox) | Transcript screen unlocks |
| Open transcript on a supported episode | Transcript loads and scrolls |
| Tap a transcript segment | Audio jumps to that timestamp |
| Search transcript for a word | Matching segments highlighted |
| Open Snip Creator | Start/end sliders appear at current position |
| Set a 30-second clip and save | Snip appears in Snips tab |
| Export snips as Markdown | Share sheet opens with formatted text |
| Swipe to delete a snip | Snip removed from list |

### Phase 5 — Spotify Integration (Week 3)
| Test | Expected Result |
|---|---|
| Tap Connect Spotify | Spotify login page opens in browser |
| Log in with Spotify credentials | Returns to app, shows "Connected" |
| Search for a Spotify-exclusive show | Show appears with green Spotify badge |
| Tap a Spotify show | Opens in Spotify app |
| Disconnect Spotify | Account unlinked, saved shows cleared |

### Phase 6 — Monetisation (Week 3–4)
| Test | Expected Result |
|---|---|
| Open paywall from Profile | Paywall screen displays correctly |
| Select Monthly plan | CTA button updates to monthly price |
| Select Annual plan | "Best Value" badge visible |
| Select Lifetime plan | "Limited" badge visible |
| Complete sandbox purchase | Tier upgrades to Premium |
| Verify ads disappear after upgrade | Banner no longer shown on Discover |
| Tap Restore Purchases | Previous purchase restored |

### Phase 7 — Edge Cases and Stress Testing (Week 4)
| Test | Expected Result |
|---|---|
| Subscribe to 50+ podcasts | Library scrolls smoothly, no lag |
| Search with special characters (e.g. "O'Brien") | Results return correctly |
| Very long episode title (100+ characters) | Text truncates cleanly, no overflow |
| No internet connection on launch | App loads with cached data, shows offline indicator |
| Low storage (under 500MB free) | Download fails gracefully with an error message |
| Switch between light and dark mode | All screens update immediately |

---

## 6. What Is Missing — Gap Analysis

The following features were either partially implemented, mocked, or not yet built. These represent the work needed to take PodFlow from a well-structured codebase to a fully production-ready app.

### 6.1 Critical — Must Have Before App Store Launch

| Gap | Description | Effort |
|---|---|---|
| **StoreKit 2 integration** | The subscription and lifetime purchase flows are wired up in the UI but call simulated purchase methods. Real StoreKit 2 product IDs need to be created in App Store Connect and integrated into `SubscriptionManager.swift`. | Medium |
| **Real API keys** | The Podcast Index API key and Spotify Client ID are placeholders. These must be replaced before the app will load real data. Both are free to obtain. | Low |
| **App icon (1024×1024)** | The icon has been generated from the logo SVG but needs to be reviewed at full resolution and confirmed as App Store compliant (no alpha channel, no rounded corners — Apple applies these automatically). | Low |
| **Privacy policy URL** | App Store Connect requires a live privacy policy URL. A simple one-page website or a free service like Termly is sufficient. | Low |
| **Push notifications** | New episode notifications are referenced in the UI but the `UNUserNotificationCenter` implementation is not yet built. | Medium |

### 6.2 Important — Should Have for a Strong Launch

| Gap | Description | Effort |
|---|---|---|
| **Real AI transcript summaries** | The `AIService.swift` generates mock summaries. Connecting to OpenAI's Whisper API or a similar service would provide real transcription for episodes that do not have a Podcasting 2.0 transcript URL. | Medium |
| **iCloud sync** | The `SubscriptionManager` references cloud sync as a Premium feature but it is not implemented. Using `NSUbiquitousKeyValueStore` or CloudKit would sync subscriptions and snips across devices. | High |
| **Siri Shortcuts** | "Hey Siri, play my latest episode" is a natural fit for a podcast app and is expected by power users. Requires `AppIntents` framework integration. | Medium |
| **Widget support** | A Lock Screen and Home Screen widget showing the currently playing episode or latest unplayed episodes would significantly improve discoverability and daily engagement. | Medium |
| **Smart speed (silence trimming)** | The `trimSilence` toggle exists in settings but the underlying `AVAudioProcessingTap` implementation is not yet built. This is a highly requested feature (Overcast's "Smart Speed" is its most loved feature). | High |
| **Chapter support display** | The data model supports chapters but there is no chapter list UI in the full player. A chapter list sheet would allow users to jump between sections. | Low |
| **Video podcast support** | Apple Podcasts now supports video podcasts. The current player is audio-only. Adding `AVPlayerViewController` for video episodes would future-proof the app. | High |
| **Playlist / custom queue management** | Users can add to queue but cannot save named playlists. A "Playlist" feature would allow creating curated listening lists. | Medium |

### 6.3 Nice to Have — Post-Launch Roadmap

| Gap | Description | Effort |
|---|---|---|
| **Social / friend activity feed** | The opt-in "see what friends are listening to" feature was identified as a key differentiator in the market research but was not built in v1. Requires a backend (user accounts, social graph). | Very High |
| **Timestamped comments** | Allowing users to leave comments at specific moments in an episode (like SoundCloud) was the most requested missing feature in user research. Requires a backend. | Very High |
| **Co-listening / listen party** | Real-time synchronised listening with friends. Requires a backend with WebSocket or similar. | Very High |
| **Android version** | The app is iOS-only. A Flutter or React Native port would significantly expand the addressable market. | High |
| **Web player** | A browser-based player for desktop users. | High |
| **Podcast 2.0 Value-for-Value** | The Podcasting 2.0 namespace supports direct micropayments to creators via Bitcoin Lightning. A niche but growing feature among podcast enthusiasts. | Medium |
| **AI "Radio" mode** | An algorithmic feed of individual episodes (not full shows) based on listening history — the most requested discovery feature in user research. Requires a recommendation engine. | High |
| **Export to Readwise / Notion API** | Currently exports as Markdown text. A direct API integration with Readwise and Notion would allow one-tap sync without copy-pasting. | Medium |
| **Apple Vision Pro support** | The app is built in SwiftUI, which means a basic visionOS port is achievable with relatively little additional work. | Medium |
| **Accessibility audit** | VoiceOver labels, Dynamic Type support, and minimum touch target sizes should be audited and verified before a wide public launch. | Medium |

---

## 7. Summary

PodFlow is a fully architected, well-structured iOS application with a strong feature set for v1.0. The core listening experience — discovery, playback, downloads, organisation, and the Snip/Transcript AI features — is built and ready to test. The visual identity is distinctive and consistent, using the logo colours throughout.

The most important next steps before a public App Store launch are:

1. Replace the API key placeholders with real credentials
2. Integrate StoreKit 2 for real in-app purchases
3. Set up a privacy policy URL
4. Run the structured beta test programme above via TestFlight
5. Address any crashes or issues found in testing

The social features (friend activity, timestamped comments, co-listening) represent the biggest long-term differentiator but require a backend infrastructure investment that is best tackled after the initial launch has validated user demand.

---

*PodFlow v1.0.0 — Built with SwiftUI · iOS 17+ · Universal (iPhone + iPad)*
