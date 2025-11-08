-- Add foreign key constraint from community_posts.user_id to profiles.id
-- This enables Supabase to understand the relationship for joins

-- First, ensure all existing user_ids in community_posts have corresponding profiles
-- (This should already be the case due to the trigger, but let's be safe)

-- Fix RLS policies for community_posts to work properly
DROP POLICY IF EXISTS "Registered users can create posts" ON community_posts;

CREATE POLICY "Registered users can create posts"
    ON community_posts FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND auth.uid() IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'anonymous'
        )
    );

-- Add the foreign key constraint
ALTER TABLE community_posts 
DROP CONSTRAINT IF EXISTS community_posts_user_id_fkey;

ALTER TABLE community_posts
ADD CONSTRAINT community_posts_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;

-- Similarly for post_likes
ALTER TABLE post_likes 
DROP CONSTRAINT IF EXISTS post_likes_user_id_fkey;

ALTER TABLE post_likes
ADD CONSTRAINT post_likes_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;

-- Similarly for post_comments
ALTER TABLE post_comments 
DROP CONSTRAINT IF EXISTS post_comments_user_id_fkey;

ALTER TABLE post_comments
ADD CONSTRAINT post_comments_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;

-- Similarly for chat_messages
ALTER TABLE chat_messages 
DROP CONSTRAINT IF EXISTS chat_messages_user_id_fkey;

ALTER TABLE chat_messages
ADD CONSTRAINT chat_messages_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES profiles(id) 
ON DELETE CASCADE;
