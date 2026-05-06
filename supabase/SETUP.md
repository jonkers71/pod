# PodFlow Supabase Setup Guide

Supabase provides user authentication, a database, and real-time sync — all for free up to 50,000 users.

## Cost
**Free** for up to 50,000 monthly active users, 500MB database, and 1GB file storage.
Paid plans start at $25/month when you outgrow the free tier.

---

## Step 1 — Create a Supabase Project
1. Go to https://app.supabase.com and sign up for a free account
2. Click **New Project**
3. Name it `podflow`
4. Choose a strong database password (save this somewhere safe)
5. Select the region closest to Australia (e.g. **ap-southeast-2 Sydney**)
6. Click **Create new project** — takes about 2 minutes to provision

---

## Step 2 — Run the Database Schema
1. In your Supabase project, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Paste the entire contents of `schema.sql` from this folder
4. Click **Run** (or press Ctrl+Enter)
5. You should see "Success. No rows returned."

---

## Step 3 — Enable Authentication
1. Go to **Authentication → Providers** in the left sidebar
2. Enable **Apple** sign-in:
   - You will need your Apple Developer Team ID and a Service ID
   - Follow Supabase's guide: https://supabase.com/docs/guides/auth/social-login/auth-apple
3. Enable **Email** sign-in (already on by default) as a fallback

---

## Step 4 — Get Your API Keys
1. Go to **Settings → API** in the left sidebar
2. Copy two values:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public key** — a long JWT string starting with `eyJ...`
3. These go into the iOS app (see Step 5)

---

## Step 5 — Add Supabase to the iOS App

### Add the Swift Package
1. In Xcode, go to **File → Add Package Dependencies**
2. Enter: `https://github.com/supabase/supabase-swift`
3. Select **Up to Next Major Version** from `2.0.0`
4. Click **Add Package**
5. Select the **Supabase** library and click **Add to Target: PodFlow**

### Configure the Client
Open `PodFlow/Services/SupabaseService.swift` (already created in the repo) and replace:
```swift
private let supabaseURL = "YOUR_SUPABASE_URL"
private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
```
with your actual values from Step 4.

---

## What Supabase Gives PodFlow

| Feature | How It Works |
|---|---|
| **Sign in with Apple** | Users tap "Sign in with Apple" — Supabase handles the OAuth flow |
| **Cross-device library sync** | Subscriptions saved to Supabase, loaded on any device |
| **Cross-device snips sync** | Snips backed up to Supabase, never lost if phone is replaced |
| **Playback position sync** | Resume any episode on any device from where you left off |
| **Personalisation data** | Listening history stored for future recommendation engine |
| **Subscription tier sync** | Premium status synced across devices (replaces iCloud KV store) |
