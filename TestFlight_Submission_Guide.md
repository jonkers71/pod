# PodFlow: From Free Sideload to App Store

**Author:** Manus AI
**Date:** May 2026

This guide is split into two parts. **Part 1** shows you how to run PodFlow on your own iPhone for free — no Apple Developer fee required. **Part 2** covers TestFlight and App Store submission when you are ready to go public.

---

## PART 1 — Free Sideloading (No $99 Fee Required)

Sideloading lets you install PodFlow directly onto your personal iPhone or iPad from Xcode using a free Apple ID. The app will run for **7 days** before Xcode needs to re-sign it (a limitation of the free tier). This is the perfect way to test the app on a real device before committing to anything.

### What You Need

- A **Mac** running macOS Ventura (13) or later
- **Xcode 15 or later** — download free from the Mac App Store
- Your **iPhone or iPad** with a USB cable
- A **free Apple ID** — the same one you use for iCloud is fine

### Step-by-Step

**Step 1 — Clone the project**

Open Terminal on your Mac and run:
```bash
git clone https://github.com/jonkers71/pod.git
cd pod
open PodFlow.xcodeproj
```

**Step 2 — Sign in to Xcode with your Apple ID**

1. In Xcode, go to **Xcode → Settings** (or press `⌘,`)
2. Click the **Accounts** tab
3. Click the **+** button at the bottom left and choose **Apple ID**
4. Sign in with your regular Apple ID (no developer account needed)

**Step 3 — Configure Signing**

1. In the left navigator, click on the **PodFlow** project (the blue icon at the top)
2. Select the **PodFlow** target
3. Go to the **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Under **Team**, select your personal Apple ID (it will show as "Your Name (Personal Team)")
6. Change the **Bundle Identifier** to something unique — add your name to make it yours, for example: `com.yourname.podflow`

> Xcode will automatically create a free development certificate and provisioning profile for you. You may see a yellow warning — this is normal for a free account.

**Step 4 — Connect your iPhone**

1. Plug your iPhone into your Mac with a USB cable
2. Unlock your iPhone and tap **Trust** when prompted
3. In Xcode, click the device selector at the top centre of the window (it may say "iPhone 15 Pro" or similar)
4. Select your iPhone from the list

**Step 5 — Build and Run**

1. Press the **Play button** (▶) in the top left of Xcode, or press `⌘R`
2. Xcode will compile the app and install it on your iPhone — this takes 1–3 minutes the first time
3. You may see a message on your iPhone: **"Could not launch PodFlow"**

**Step 6 — Trust the Developer Certificate on Your iPhone**

Because this is a free account (not a paid developer), iOS requires you to manually trust the certificate:

1. On your iPhone, go to **Settings → General → VPN & Device Management**
2. Under **Developer App**, tap your Apple ID email address
3. Tap **Trust "[Your Apple ID]"**
4. Tap **Trust** again to confirm

**Step 7 — Open PodFlow**

Go back to your home screen and tap the PodFlow icon. The app will launch! 🎉

### Important Limitations of Free Sideloading

| Limitation | Detail |
|---|---|
| **7-day expiry** | The app stops working after 7 days. To re-enable it, simply connect your iPhone to your Mac and press ▶ in Xcode again. It takes about 30 seconds. |
| **3 app limit** | A free Apple ID can only have 3 sideloaded apps installed at a time |
| **No TestFlight** | You cannot share the app with others via TestFlight on a free account |
| **No push notifications** | Push notifications require a paid developer account |
| **Your device only** | The app can only be installed on devices registered to your Apple ID |

### Adding Your API Keys (Optional but Recommended)

The app will run with mock/sample data without any API keys. To get real podcasts loading:

1. **Podcast Index** (free) — Sign up at [api.podcastindex.org](https://api.podcastindex.org). You will receive an API Key and Secret instantly. Open `PodFlow/Services/PodcastIndexService.swift` and replace:
   - `YOUR_PODCAST_INDEX_API_KEY` with your key
   - `YOUR_PODCAST_INDEX_API_SECRET` with your secret

2. **Spotify** (free) — Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard), create an app, and copy your Client ID. Open `PodFlow/Services/SpotifyAuthService.swift` and replace `YOUR_SPOTIFY_CLIENT_ID`. Also add `podflow://spotify-callback` to your Redirect URIs in the Spotify dashboard.

---

## PART 2 — TestFlight & App Store (Requires $99/year Apple Developer Program)

Once you have tested the app on your device and are happy with it, follow these steps to distribute it publicly.

### Prerequisites

- Enrol in the **Apple Developer Program** at [developer.apple.com/programs](https://developer.apple.com/programs) ($99/year)
- A Mac with **Xcode 15 or later**

### Step 1 — Update Signing to Paid Account

1. Open `PodFlow.xcodeproj` in Xcode
2. Go to **Signing & Capabilities** for the PodFlow target
3. Under **Team**, switch from your Personal Team to your **paid Developer Program team**
4. Xcode will automatically update your certificates and provisioning profiles

### Step 2 — Create Your App in App Store Connect

1. Log in to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps → +** → **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** PodFlow
   - **Bundle ID:** `com.yourname.podflow` (must match Xcode)
   - **SKU:** `PODFLOW-001`

### Step 3 — Archive and Upload

1. In Xcode, set the destination to **Any iOS Device (arm64)**
2. Go to **Product → Archive**
3. When the Organizer opens, click **Distribute App → TestFlight & App Store → Upload**
4. Follow the prompts and click **Upload**

### Step 4 — TestFlight Internal Testing

1. In App Store Connect, go to the **TestFlight** tab
2. Wait for the build to finish processing (10–30 minutes)
3. Answer the Export Compliance question (select "Yes" for standard encryption)
4. Go to **Internal Testing → +** to create a group
5. Add your email address — you will receive a TestFlight invite immediately
6. Install the **TestFlight app** on your iPhone from the App Store and accept the invite

### Step 5 — External Beta (Share with Others)

1. Go to **External Testing → +** to create a public group
2. Add your build and fill in the **Test Information** (what to test, feedback email)
3. Submit for **Beta App Review** (usually 24–48 hours)
4. Once approved, generate a **Public Link** to share with anyone

### Step 6 — App Store Submission

When you are ready to go live:

1. **Screenshots** — Required for 6.5-inch iPhone and 12.9-inch iPad
2. **Description & Keywords** — Write a compelling listing
3. **Privacy Policy** — Must be a live URL (e.g., a simple page on your website)
4. **In-App Purchases** — Set up Monthly, Annual, and Lifetime products in App Store Connect under **Monetization → In-App Purchases**
5. **Submit for Review** — Typically 24–72 hours

---

## Cost Summary

| Stage | Cost | What You Get |
|---|---|---|
| Free sideload | **$0** | App on your personal device, 7-day expiry |
| Apple Developer Program | **$99/year** | TestFlight, App Store, unlimited devices |
| Podcast Index API | **$0** | 4.5M+ podcasts |
| Spotify API | **$0** | Spotify show search & integration |
| **Total to launch** | **$99/year** | Full public App Store release |

---

## Quick Troubleshooting

| Problem | Solution |
|---|---|
| "Could not launch" on iPhone | Go to Settings → General → VPN & Device Management → Trust your Apple ID |
| "No account for team" error in Xcode | Go to Xcode → Settings → Accounts and add your Apple ID |
| App crashes on launch | Make sure you are running iOS 17 or later on your device |
| Podcasts not loading | Add your Podcast Index API key in `PodcastIndexService.swift` |
| Build fails with signing error | Change the Bundle Identifier to something unique (add your name) |
