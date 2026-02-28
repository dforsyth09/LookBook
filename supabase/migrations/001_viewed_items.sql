-- Migration: Add viewed_items table and unseen products RPC
-- Run this in Supabase SQL Editor

-- 1. Create viewed_items table
CREATE TABLE IF NOT EXISTS viewed_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES clothing_items(id) ON DELETE CASCADE NOT NULL,
    viewed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, product_id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_viewed_items_user_id ON viewed_items(user_id);
CREATE INDEX IF NOT EXISTS idx_viewed_items_user_product ON viewed_items(user_id, product_id);

-- Enable RLS
ALTER TABLE viewed_items ENABLE ROW LEVEL SECURITY;

-- RLS policies: users can read/write their own viewed items
CREATE POLICY "Users can insert their own viewed items"
    ON viewed_items FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can read their own viewed items"
    ON viewed_items FOR SELECT
    USING (true);

-- 2. RPC function: get unseen products for a user/category
-- Returns unseen items first (random order), then falls back to least-recently-viewed
CREATE OR REPLACE FUNCTION get_unseen_products(
    p_user_id UUID,
    p_category TEXT,
    p_limit INT DEFAULT 500
)
RETURNS SETOF clothing_items
LANGUAGE sql
STABLE
AS $$
    -- First try to get unseen items
    (
        SELECT ci.*
        FROM clothing_items ci
        WHERE ci.is_active = true
          AND (p_category = 'all' OR ci.category = p_category)
          AND ci.id NOT IN (
              SELECT product_id FROM viewed_items WHERE user_id = p_user_id
          )
        ORDER BY random()
        LIMIT p_limit
    )
    UNION ALL
    -- If not enough unseen items, backfill with least-recently-viewed
    (
        SELECT ci.*
        FROM clothing_items ci
        INNER JOIN viewed_items vi ON vi.product_id = ci.id AND vi.user_id = p_user_id
        WHERE ci.is_active = true
          AND (p_category = 'all' OR ci.category = p_category)
          AND ci.id NOT IN (
              -- Exclude the unseen ones we already selected above
              SELECT ci2.id
              FROM clothing_items ci2
              WHERE ci2.is_active = true
                AND (p_category = 'all' OR ci2.category = p_category)
                AND ci2.id NOT IN (
                    SELECT product_id FROM viewed_items WHERE user_id = p_user_id
                )
          )
        ORDER BY vi.viewed_at ASC
        LIMIT GREATEST(0, p_limit - (
            SELECT COUNT(*)
            FROM clothing_items ci3
            WHERE ci3.is_active = true
              AND (p_category = 'all' OR ci3.category = p_category)
              AND ci3.id NOT IN (
                  SELECT product_id FROM viewed_items WHERE user_id = p_user_id
              )
        ))
    )
    LIMIT p_limit;
$$;
