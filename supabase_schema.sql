-- =====================================================
-- GraceGrid Supabase Schema — Step 3: Auth Foundation
-- =====================================================
-- Run this ENTIRE script in your Supabase SQL Editor
-- (Dashboard → SQL Editor → New Query → Paste → Run)
-- =====================================================

-- 1. Drop any existing broken trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT NOT NULL DEFAULT '',
  bio TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. RLS policies for profiles
-- Anyone can read profiles (public profiles)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles
  FOR SELECT
  USING (true);

-- Users can insert their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 5. Create trigger function to auto-create profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$;

-- 6. Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 7. Updated_at auto-update function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 8. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

-- =====================================================
-- Backfill: Create profile rows for any existing auth
-- users who don't have one yet (safe to re-run)
-- =====================================================
INSERT INTO public.profiles (id, display_name, avatar_url)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data->>'display_name', ''),
  COALESCE(u.raw_user_meta_data->>'avatar_url', '')
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
);

-- =====================================================
-- 9. Storage Setup for Avatars (Run in SQL Editor)
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to view avatars
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Allow authenticated users to upload their own avatar
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Allow authenticated users to update/upsert their own avatar
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- =====================================================
-- 10. Community Posts (Social Feed) — Step 5
-- =====================================================

-- Posts table
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Anyone can read posts
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON public.posts;
CREATE POLICY "Posts are viewable by everyone"
  ON public.posts FOR SELECT USING (true);

-- Authenticated users can create posts
DROP POLICY IF EXISTS "Authenticated users can create posts" ON public.posts;
CREATE POLICY "Authenticated users can create posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own posts
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own posts
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
CREATE POLICY "Users can delete own posts"
  ON public.posts FOR DELETE
  USING (auth.uid() = user_id);

-- Updated_at trigger for posts
DROP TRIGGER IF EXISTS posts_updated_at ON public.posts;
CREATE TRIGGER posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- 11. Post Likes (junction table)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (post_id, user_id)
);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

-- Anyone can see likes
DROP POLICY IF EXISTS "Likes are viewable by everyone" ON public.post_likes;
CREATE POLICY "Likes are viewable by everyone"
  ON public.post_likes FOR SELECT USING (true);

-- Authenticated users can like
DROP POLICY IF EXISTS "Users can like posts" ON public.post_likes;
CREATE POLICY "Users can like posts"
  ON public.post_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can un-like (delete own likes)
DROP POLICY IF EXISTS "Users can unlike posts" ON public.post_likes;
CREATE POLICY "Users can unlike posts"
  ON public.post_likes FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 12. Post Comments
-- =====================================================

CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

-- Anyone can read comments
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.post_comments;
CREATE POLICY "Comments are viewable by everyone"
  ON public.post_comments FOR SELECT USING (true);

-- Authenticated users can comment
DROP POLICY IF EXISTS "Users can comment on posts" ON public.post_comments;
CREATE POLICY "Users can comment on posts"
  ON public.post_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
DROP POLICY IF EXISTS "Users can delete own comments" ON public.post_comments;
CREATE POLICY "Users can delete own comments"
  ON public.post_comments FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 13. RPC functions for incrementing/decrementing counts
-- =====================================================

CREATE OR REPLACE FUNCTION public.increment_like_count(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts SET like_count = like_count + 1 WHERE id = p_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_like_count(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = p_post_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_comment_count(p_post_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = p_post_id;
END;
$$;

-- =====================================================
-- 14. Grants for social tables
-- =====================================================
GRANT SELECT ON public.posts TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT SELECT ON public.post_likes TO anon, authenticated;
GRANT INSERT, DELETE ON public.post_likes TO authenticated;
GRANT SELECT ON public.post_comments TO anon, authenticated;
GRANT INSERT, DELETE ON public.post_comments TO authenticated;

-- =====================================================
-- 15. Explicit FKs from posts/comments → profiles
--     (PostgREST needs these to auto-join with profiles)
-- =====================================================
ALTER TABLE public.posts
  DROP CONSTRAINT IF EXISTS posts_profiles_fkey;
ALTER TABLE public.posts
  ADD CONSTRAINT posts_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.post_comments
  DROP CONSTRAINT IF EXISTS post_comments_profiles_fkey;
ALTER TABLE public.post_comments
  ADD CONSTRAINT post_comments_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- =====================================================
-- 16. Prayer Requests — Step 6
-- =====================================================

CREATE TABLE IF NOT EXISTS public.prayer_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  request_text TEXT NOT NULL DEFAULT '',
  praying_count INT NOT NULL DEFAULT 0,
  is_answered BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.prayer_requests ENABLE ROW LEVEL SECURITY;

-- Anyone can read prayer requests
DROP POLICY IF EXISTS "Prayer requests are viewable by everyone" ON public.prayer_requests;
CREATE POLICY "Prayer requests are viewable by everyone"
  ON public.prayer_requests FOR SELECT USING (true);

-- Authenticated users can create prayer requests
DROP POLICY IF EXISTS "Users can create prayer requests" ON public.prayer_requests;
CREATE POLICY "Users can create prayer requests"
  ON public.prayer_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own prayer requests
DROP POLICY IF EXISTS "Users can update own prayer requests" ON public.prayer_requests;
CREATE POLICY "Users can update own prayer requests"
  ON public.prayer_requests FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own prayer requests
DROP POLICY IF EXISTS "Users can delete own prayer requests" ON public.prayer_requests;
CREATE POLICY "Users can delete own prayer requests"
  ON public.prayer_requests FOR DELETE
  USING (auth.uid() = user_id);

-- Updated_at trigger
DROP TRIGGER IF EXISTS prayer_requests_updated_at ON public.prayer_requests;
CREATE TRIGGER prayer_requests_updated_at
  BEFORE UPDATE ON public.prayer_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- FK to profiles for PostgREST join
ALTER TABLE public.prayer_requests
  DROP CONSTRAINT IF EXISTS prayer_requests_profiles_fkey;
ALTER TABLE public.prayer_requests
  ADD CONSTRAINT prayer_requests_profiles_fkey
  FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- =====================================================
-- 17. Prayer Prays (junction: who prayed for what)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.prayer_prays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prayer_id UUID NOT NULL REFERENCES public.prayer_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (prayer_id, user_id)
);

ALTER TABLE public.prayer_prays ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Prays are viewable by everyone" ON public.prayer_prays;
CREATE POLICY "Prays are viewable by everyone"
  ON public.prayer_prays FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can pray" ON public.prayer_prays;
CREATE POLICY "Users can pray"
  ON public.prayer_prays FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can un-pray" ON public.prayer_prays;
CREATE POLICY "Users can un-pray"
  ON public.prayer_prays FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 18. RPC functions for prayer counts
-- =====================================================

CREATE OR REPLACE FUNCTION public.increment_praying_count(p_prayer_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.prayer_requests SET praying_count = praying_count + 1 WHERE id = p_prayer_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_praying_count(p_prayer_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.prayer_requests SET praying_count = GREATEST(praying_count - 1, 0) WHERE id = p_prayer_id;
END;
$$;

-- =====================================================
-- 19. Grants for prayer tables
-- =====================================================
GRANT SELECT ON public.prayer_requests TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.prayer_requests TO authenticated;
GRANT SELECT ON public.prayer_prays TO anon, authenticated;
GRANT INSERT, DELETE ON public.prayer_prays TO authenticated;
