/**
 * PodFlow API Proxy — Cloudflare Worker
 *
 * This worker acts as a secure proxy between the PodFlow iOS app and the
 * Podcast Index API. The API key and secret never leave this server.
 *
 * Deploy to Cloudflare Workers:
 *   1. Go to https://workers.cloudflare.com and create a free account
 *   2. Create a new Worker and paste this code
 *   3. Add your secrets in Settings → Variables:
 *      - PODCAST_INDEX_KEY    = your API key
 *      - PODCAST_INDEX_SECRET = your API secret
 *   4. Note your worker URL (e.g. https://podflow-proxy.yourname.workers.dev)
 *   5. Update PROXY_BASE_URL in PodcastIndexService.swift with that URL
 *
 * The app sends requests to:
 *   https://your-worker.workers.dev/api/search?q=sport
 *   https://your-worker.workers.dev/api/trending
 *   https://your-worker.workers.dev/api/episodes?feedUrl=...
 *
 * The worker adds the auth headers and forwards to Podcast Index.
 */

// CORS headers — allows the iOS app to call this worker
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-App-Token",
  "Content-Type": "application/json",
};

const PODCAST_INDEX_BASE = "https://api.podcastindex.org/api/1.0";

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    // Only allow GET requests
    if (request.method !== "GET") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: CORS_HEADERS,
      });
    }

    const url = new URL(request.url);
    const path = url.pathname; // e.g. /api/search

    // Route mapping: proxy path → Podcast Index endpoint
    let podcastIndexPath = "";
    const params = new URLSearchParams(url.search);

    if (path === "/api/search") {
      podcastIndexPath = "/search/byterm";
    } else if (path === "/api/trending") {
      podcastIndexPath = "/podcasts/trending";
    } else if (path === "/api/episodes") {
      podcastIndexPath = "/episodes/byfeedurl";
    } else if (path === "/api/episodes/byid") {
      podcastIndexPath = "/episodes/byfeedid";
    } else if (path === "/api/podcast/byfeedurl") {
      podcastIndexPath = "/podcasts/byfeedurl";
    } else {
      return new Response(JSON.stringify({ error: "Unknown endpoint" }), {
        status: 404,
        headers: CORS_HEADERS,
      });
    }

    // Build auth headers using SHA-1 HMAC
    const apiKey    = env.PODCAST_INDEX_KEY;
    const apiSecret = env.PODCAST_INDEX_SECRET;
    const epochTime = Math.floor(Date.now() / 1000);
    const hashInput = `${apiKey}${apiSecret}${epochTime}`;

    // SHA-1 hash using Web Crypto API
    const encoder = new TextEncoder();
    const data     = encoder.encode(hashInput);
    const hashBuffer = await crypto.subtle.digest("SHA-1", data);
    const hashArray  = Array.from(new Uint8Array(hashBuffer));
    const hashHex    = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

    // Forward request to Podcast Index
    const targetURL = `${PODCAST_INDEX_BASE}${podcastIndexPath}?${params.toString()}`;

    const response = await fetch(targetURL, {
      headers: {
        "X-Auth-Date":   String(epochTime),
        "X-Auth-Key":    apiKey,
        "Authorization": hashHex,
        "User-Agent":    "PodFlow/1.0",
      },
    });

    const body = await response.text();

    return new Response(body, {
      status: response.status,
      headers: {
        ...CORS_HEADERS,
        "Cache-Control": "public, max-age=60", // Cache responses for 60 seconds
      },
    });
  },
};
