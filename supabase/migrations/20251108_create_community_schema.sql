-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'moderator', 'user', 'anonymous')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    total_catches INTEGER DEFAULT 0,
    total_posts INTEGER DEFAULT 0,
    followers INTEGER DEFAULT 0,
    following INTEGER DEFAULT 0,
    is_public_profile BOOLEAN DEFAULT TRUE,
    preferences JSONB
);

-- Create index on profiles
CREATE INDEX IF NOT EXISTS profiles_role_idx ON profiles(role);
CREATE INDEX IF NOT EXISTS profiles_created_at_idx ON profiles(created_at DESC);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (is_public_profile = TRUE OR auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Update catch_logs table to add visibility
ALTER TABLE catch_logs ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;
ALTER TABLE catch_logs ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

-- Create index on catch_logs
CREATE INDEX IF NOT EXISTS catch_logs_is_public_idx ON catch_logs(is_public);
CREATE INDEX IF NOT EXISTS catch_logs_user_id_created_at_idx ON catch_logs(user_id, created_at DESC);

-- Update catch_logs RLS policies
DROP POLICY IF EXISTS "Users can view own catch reports" ON catch_logs;
CREATE POLICY "Users can view public catch reports or own reports"
    ON catch_logs FOR SELECT
    USING (is_public = TRUE OR auth.uid() = user_id);

-- Create chat_channels table
CREATE TABLE IF NOT EXISTS chat_channels (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    member_count INTEGER DEFAULT 0
);

-- Create index on chat_channels
CREATE INDEX IF NOT EXISTS chat_channels_created_at_idx ON chat_channels(created_at DESC);

-- Enable RLS on chat_channels
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active channels"
    ON chat_channels FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Only admins can create channels"
    ON chat_channels FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'moderator')
        )
    );

CREATE POLICY "Only admins can update channels"
    ON chat_channels FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'moderator')
        )
    );

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    channel_id UUID REFERENCES chat_channels(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    media_url TEXT,
    reply_to UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Create indexes on chat_messages
CREATE INDEX IF NOT EXISTS chat_messages_channel_id_idx ON chat_messages(channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_reply_to_idx ON chat_messages(reply_to);

-- Enable RLS on chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in channels they have access to"
    ON chat_messages FOR SELECT
    USING (TRUE); -- All authenticated users can view messages

CREATE POLICY "Registered users can send messages"
    ON chat_messages FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role != 'anonymous'
        )
    );

CREATE POLICY "Users can update own messages"
    ON chat_messages FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can delete any message"
    ON chat_messages FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'moderator')
        )
    );

-- Create channel_subscriptions table (for notifications)
CREATE TABLE IF NOT EXISTS channel_subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    channel_id UUID REFERENCES chat_channels(id) ON DELETE CASCADE NOT NULL,
    is_muted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, channel_id)
);

-- Create index on channel_subscriptions
CREATE INDEX IF NOT EXISTS channel_subscriptions_user_id_idx ON channel_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS channel_subscriptions_channel_id_idx ON channel_subscriptions(channel_id);

-- Enable RLS on channel_subscriptions
ALTER TABLE channel_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own subscriptions"
    ON channel_subscriptions FOR ALL
    USING (auth.uid() = user_id);

-- Create user_bans table (for moderation)
CREATE TABLE IF NOT EXISTS user_bans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    banned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    channel_id UUID REFERENCES chat_channels(id) ON DELETE CASCADE, -- NULL means app-wide ban
    reason TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- Create index on user_bans
CREATE INDEX IF NOT EXISTS user_bans_user_id_idx ON user_bans(user_id, is_active);
CREATE INDEX IF NOT EXISTS user_bans_channel_id_idx ON user_bans(channel_id);

-- Enable RLS on user_bans
ALTER TABLE user_bans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bans"
    ON user_bans FOR SELECT
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator')
    ));

CREATE POLICY "Only admins can manage bans"
    ON user_bans FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'moderator')
        )
    );

-- Create community_posts table
CREATE TABLE IF NOT EXISTS community_posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    media_urls TEXT[], -- Array of media URLs
    catch_log_id UUID REFERENCES catch_logs(id) ON DELETE SET NULL, -- Link to catch report if it's a catch post
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Create indexes on community_posts
CREATE INDEX IF NOT EXISTS community_posts_user_id_idx ON community_posts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS community_posts_created_at_idx ON community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS community_posts_catch_log_id_idx ON community_posts(catch_log_id);

-- Enable RLS on community_posts
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view posts"
    ON community_posts FOR SELECT
    USING (TRUE);

CREATE POLICY "Registered users can create posts"
    ON community_posts FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role != 'anonymous'
        )
    );

CREATE POLICY "Users can update own posts"
    ON community_posts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
    ON community_posts FOR DELETE
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator')
    ));

-- Create post_likes table
CREATE TABLE IF NOT EXISTS post_likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Create index on post_likes
CREATE INDEX IF NOT EXISTS post_likes_post_id_idx ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS post_likes_user_id_idx ON post_likes(user_id);

-- Enable RLS on post_likes
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view likes"
    ON post_likes FOR SELECT
    USING (TRUE);

CREATE POLICY "Registered users can like posts"
    ON post_likes FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role != 'anonymous'
        )
    );

CREATE POLICY "Users can unlike posts"
    ON post_likes FOR DELETE
    USING (auth.uid() = user_id);

-- Create post_comments table
CREATE TABLE IF NOT EXISTS post_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Create index on post_comments
CREATE INDEX IF NOT EXISTS post_comments_post_id_idx ON post_comments(post_id, created_at);
CREATE INDEX IF NOT EXISTS post_comments_user_id_idx ON post_comments(user_id);

-- Enable RLS on post_comments
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view comments"
    ON post_comments FOR SELECT
    USING (TRUE);

CREATE POLICY "Registered users can comment"
    ON post_comments FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role != 'anonymous'
        )
    );

CREATE POLICY "Users can update own comments"
    ON post_comments FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
    ON post_comments FOR DELETE
    USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'moderator')
    ));

-- Create follows table
CREATE TABLE IF NOT EXISTS follows (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- Create indexes on follows
CREATE INDEX IF NOT EXISTS follows_follower_id_idx ON follows(follower_id);
CREATE INDEX IF NOT EXISTS follows_following_id_idx ON follows(following_id);

-- Enable RLS on follows
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view follows"
    ON follows FOR SELECT
    USING (TRUE);

CREATE POLICY "Users can follow others"
    ON follows FOR INSERT
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
    ON follows FOR DELETE
    USING (auth.uid() = follower_id);

-- Function to update likes count on community_posts
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_likes_count_trigger
AFTER INSERT OR DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Function to update comments count on community_posts
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER post_comments_count_trigger
AFTER INSERT OR DELETE ON post_comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Function to update follower/following counts on profiles
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles SET following = following + 1 WHERE id = NEW.follower_id;
        UPDATE profiles SET followers = followers + 1 WHERE id = NEW.following_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE profiles SET following = following - 1 WHERE id = OLD.follower_id;
        UPDATE profiles SET followers = followers - 1 WHERE id = OLD.following_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER follow_counts_trigger
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, display_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', 'User'),
        CASE
            WHEN NEW.is_anonymous THEN 'anonymous'
            ELSE 'user'
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
