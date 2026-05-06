# PodFlow Cloudflare Worker — Deployment Guide

This worker acts as a secure proxy between the PodFlow iOS app and the Podcast Index API.
Your API key and secret live **only on Cloudflare's servers** — never in the app binary.

## Cost
**Free.** Cloudflare Workers free tier allows 100,000 requests per day, which is more than
enough for a podcast app with thousands of users. No credit card required.

## Step 1 — Create a Cloudflare Account
Go to https://workers.cloudflare.com and sign up for a free account.

## Step 2 — Create a New Worker
1. In the Cloudflare dashboard, click **Workers & Pages** in the left sidebar
2. Click **Create Application**
3. Click **Create Worker**
4. Give it a name: `podflow-proxy`
5. Click **Deploy**

## Step 3 — Paste the Worker Code
1. Click **Edit Code**
2. Delete all the default code
3. Paste the entire contents of `worker.js` from this folder
4. Click **Save and Deploy**

## Step 4 — Add Your Secret Keys
1. In your worker's settings, click **Settings → Variables**
2. Under **Environment Variables**, click **Add variable**
3. Add two secrets (tick **Encrypt** for both):
   - Name: `PODCAST_INDEX_KEY` — Value: your Podcast Index API key
   - Name: `PODCAST_INDEX_SECRET` — Value: your Podcast Index API secret
4. Click **Save and Deploy**

## Step 5 — Note Your Worker URL
Your worker will have a URL like:
```
https://podflow-proxy.yourname.workers.dev
```
Copy this URL — you will need it in the next step.

## Step 6 — Update the iOS App
Open `PodFlow/Services/PodcastIndexService.swift` and change:
```swift
private let baseURL = "https://api.podcastindex.org/api/1.0"
```
to:
```swift
private let baseURL = "https://podflow-proxy.yourname.workers.dev/api"
```

Also remove the `authHeaders()` method and all the obfuscated key arrays —
they are no longer needed since the worker handles authentication.

## Step 7 — Test It
Open your browser and visit:
```
https://podflow-proxy.yourname.workers.dev/api/trending?max=5&lang=en
```
You should see a JSON response with trending podcasts. If you do, it is working.

## Endpoint Reference

| App calls | Worker forwards to |
|---|---|
| `/api/search?q=sport&max=20` | Podcast Index `/search/byterm` |
| `/api/trending?max=20&lang=en` | Podcast Index `/podcasts/trending` |
| `/api/episodes?url=...&max=30` | Podcast Index `/episodes/byfeedurl` |
| `/api/episodes/byid?id=...` | Podcast Index `/episodes/byfeedid` |
| `/api/podcast/byfeedurl?url=...` | Podcast Index `/podcasts/byfeedurl` |
