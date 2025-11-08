-- ============================================
-- ANGLERS SPOT - PROFILES TABLE SETUP
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Drop existing objects if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP TABLE IF EXISTS profiles CASCADE;

-- Step 2: Create profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    role TEXT DEFAULT 'user' NOT NULL CHECK (role IN ('admin', 'moderator', 'user', 'anonymous')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ,
    total_catches INTEGER DEFAULT 0 NOT NULL,
    total_posts INTEGER DEFAULT 0 NOT NULL,
    followers INTEGER DEFAULT 0 NOT NULL,
    following INTEGER DEFAULT 0 NOT NULL,
    is_public_profile BOOLEAN DEFAULT TRUE NOT NULL,
    preferences JSONB
);

-- Step 3: Create indexes
CREATE INDEX profiles_role_idx ON profiles(role);
CREATE INDEX profiles_created_at_idx ON profiles(created_at DESC);

-- Step 4: Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
CREATE POLICY "Anyone can view public profiles or own profile"
    ON profiles FOR SELECT
    USING (is_public_profile = TRUE OR auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Step 6: Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, role, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', 'User'),
        CASE 
            WHEN NEW.is_anonymous = true THEN 'anonymous'
            ELSE 'user'
        END,
        NOW()
    );
    RETURN NEW;
EXCEPTION
    WHEN others THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 7: Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Step 8: Verify setup
DO $$
BEGIN
    RAISE NOTICE 'Setup complete!';
    RAISE NOTICE 'Table exists: %', EXISTS (SELECT FROM pg_tables WHERE tablename = 'profiles');
    RAISE NOTICE 'Trigger exists: %', EXISTS (SELECT FROM pg_trigger WHERE tgname = 'on_auth_user_created');
END $$;
