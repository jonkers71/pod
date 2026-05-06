-- PodFlow Supabase Database Schema
-- Run this in the Supabase SQL Editor at https://app.supabase.com

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES
-- Extends Supabase auth.users with app-specific data
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.profiles (
    id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username        TEXT,
    display_name    TEXT,
    avatar_url      TEXT,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'lifetime')),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────────────────────
-- SUBSCRIPTIONS (podcast subscriptions, not payment subscriptions)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.podcast_subscriptions (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    podcast_id      TEXT NOT NULL,          -- Podcast Index feed ID
    podcast_title   TEXT NOT NULL,
    podcast_author  TEXT,
    podcast_image   TEXT,
    feed_url        TEXT NOT NULL,
    categories      TEXT[],
    subscribed_at   TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, podcast_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- SNIPS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.snips (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    episode_id      TEXT NOT NULL,
    episode_title   TEXT NOT NULL,
    podcast_title   TEXT NOT NULL,
    podcast_image   TEXT,
    start_time      FLOAT NOT NULL,
    end_time        FLOAT NOT NULL,
    transcript_text TEXT,
    summary         TEXT,
    note            TEXT DEFAULT '',
    tags            TEXT[] DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAYBACK POSITIONS
-- Syncs episode progress across devices
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.playback_positions (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    episode_id      TEXT NOT NULL,
    podcast_id      TEXT NOT NULL,
    position        FLOAT NOT NULL DEFAULT 0,
    duration        FLOAT,
    is_played       BOOLEAN DEFAULT FALSE,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, episode_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- LISTENING HISTORY (for personalisation)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE public.listening_history (
    id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    episode_id      TEXT NOT NULL,
    podcast_id      TEXT NOT NULL,
    podcast_title   TEXT,
    categories      TEXT[],
    listened_at     TIMESTAMPTZ DEFAULT NOW(),
    percent_played  FLOAT DEFAULT 0,        -- 0.0 to 1.0
    was_completed   BOOLEAN DEFAULT FALSE
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- Users can only see and modify their own data
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.podcast_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.snips                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playback_positions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listening_history    ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Subscriptions
CREATE POLICY "Users can manage own subscriptions"
    ON public.podcast_subscriptions FOR ALL USING (auth.uid() = user_id);

-- Snips
CREATE POLICY "Users can manage own snips"
    ON public.snips FOR ALL USING (auth.uid() = user_id);

-- Playback positions
CREATE POLICY "Users can manage own playback positions"
    ON public.playback_positions FOR ALL USING (auth.uid() = user_id);

-- Listening history
CREATE POLICY "Users can manage own listening history"
    ON public.listening_history FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- INDEXES for performance
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX idx_subscriptions_user     ON public.podcast_subscriptions(user_id);
CREATE INDEX idx_snips_user             ON public.snips(user_id);
CREATE INDEX idx_snips_episode          ON public.snips(episode_id);
CREATE INDEX idx_playback_user_episode  ON public.playback_positions(user_id, episode_id);
CREATE INDEX idx_history_user           ON public.listening_history(user_id);
CREATE INDEX idx_history_categories     ON public.listening_history USING GIN(categories);
