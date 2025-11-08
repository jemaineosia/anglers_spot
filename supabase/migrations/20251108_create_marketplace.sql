-- Create marketplace_items table
CREATE TABLE IF NOT EXISTS marketplace_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    category TEXT,
    condition TEXT, -- e.g., 'new', 'like-new', 'good', 'fair', 'poor'
    location TEXT,
    image_urls TEXT[] DEFAULT '{}',
    is_sold BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    views_count INTEGER DEFAULT 0
);

-- Create indexes
CREATE INDEX IF NOT EXISTS marketplace_items_user_id_idx ON marketplace_items(user_id);
CREATE INDEX IF NOT EXISTS marketplace_items_created_at_idx ON marketplace_items(created_at DESC);
CREATE INDEX IF NOT EXISTS marketplace_items_is_sold_idx ON marketplace_items(is_sold);
CREATE INDEX IF NOT EXISTS marketplace_items_category_idx ON marketplace_items(category);

-- Enable RLS
ALTER TABLE marketplace_items ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view available items"
    ON marketplace_items FOR SELECT
    USING (TRUE);

CREATE POLICY "Registered users can create items"
    ON marketplace_items FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role != 'anonymous'
        )
    );

CREATE POLICY "Users can update own items"
    ON marketplace_items FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own items or admins can delete any"
    ON marketplace_items FOR DELETE
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'moderator')
        )
    );

-- Add comment
COMMENT ON TABLE marketplace_items IS 'Marketplace items for buying and selling fishing gear and equipment';
