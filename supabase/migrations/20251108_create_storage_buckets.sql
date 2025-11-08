-- Create storage buckets for the app

-- Create community-media bucket for post images
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-media', 'community-media', true)
ON CONFLICT (id) DO NOTHING;

-- Create avatars bucket for user profile pictures
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create catch-photos bucket for catch report images (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('catch-photos', 'catch-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for community-media bucket
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload community media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-media');

-- Allow anyone to view public media
CREATE POLICY "Anyone can view community media"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'community-media');

-- Allow users to update their own uploads
CREATE POLICY "Users can update own community media"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'community-media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own community media"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'community-media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Set up storage policies for avatars bucket
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Set up storage policies for catch-photos bucket
CREATE POLICY "Authenticated users can upload catch photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'catch-photos');

CREATE POLICY "Anyone can view catch photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'catch-photos');

CREATE POLICY "Users can update own catch photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'catch-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own catch photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'catch-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
