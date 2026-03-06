-- ============================================================
-- MIGRATION: Add Advisory Request System to Conversations Table
-- ============================================================
-- Run this SQL in Supabase SQL Editor to update existing conversations table

-- 1. Add new columns
ALTER TABLE conversations 
  ADD COLUMN IF NOT EXISTS rae_district TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'resolved'));

-- 2. Make sme_uid nullable (for pending requests)
ALTER TABLE conversations 
  ALTER COLUMN sme_uid DROP NOT NULL;

-- 3. Create new indexes
CREATE INDEX IF NOT EXISTS idx_conversations_rae_district ON conversations(rae_district);
CREATE INDEX IF NOT EXISTS idx_conversations_status ON conversations(status);

-- 4. Update existing conversations to have 'active' status
UPDATE conversations SET status = 'active' WHERE status IS NULL OR status = '';

-- 5. Verify changes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'conversations'
ORDER BY ordinal_position;

-- Expected columns:
-- - id (uuid)
-- - rae_uid (text, not null)
-- - sme_uid (text, nullable) ← Changed!
-- - rae_name (text)
-- - rae_code (text)
-- - rae_district (text) ← New!
-- - status (text, default 'pending') ← New!
-- - last_message (text)
-- - last_message_at (timestamp)
-- - unread_count (integer)
-- - is_resolved (boolean)
-- - created_at (timestamp)
