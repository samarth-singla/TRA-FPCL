-- ============================================================
-- MIGRATION: Add FCM Token Support for Push Notifications
-- ============================================================
-- Run this SQL in Supabase SQL Editor

-- 1. Add fcm_token column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Create index for efficient FCM token lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token);

-- 3. Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'fcm_token';

-- Expected result:
-- column_name | data_type | is_nullable
-- fcm_token   | text      | YES

-- 4. (Optional) View profiles that have FCM tokens registered
-- SELECT uid, name, role, district, 
--        SUBSTRING(fcm_token, 1, 20) || '...' as token_preview
-- FROM profiles 
-- WHERE fcm_token IS NOT NULL;
