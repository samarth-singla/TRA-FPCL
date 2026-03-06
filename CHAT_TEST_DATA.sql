-- ============================================================
-- TEST DATA FOR CHAT FEATURE
-- ============================================================
-- Run this SQL in Supabase SQL Editor to create sample conversations and messages for testing

-- IMPORTANT: Replace these UIDs with actual UIDs from your profiles table
-- You can find them by running: SELECT uid, name, role FROM profiles;

-- Example: 
-- SET @rae_uid = 'your-rae-firebase-uid-here';
-- SET @sme_uid = 'your-sme-firebase-uid-here';

-- For this example, I'll use placeholder values - REPLACE THEM!
DO $$
DECLARE
  v_rae_uid TEXT := 'REPLACE_WITH_RAE_FIREBASE_UID';
  v_sme_uid TEXT := 'REPLACE_WITH_SME_FIREBASE_UID';
  v_rae_name TEXT := 'Ramesh Kumar';
  v_sme_name TEXT := 'District Advisor';
  v_conversation_id UUID;
BEGIN
  -- Create a sample conversation
  INSERT INTO conversations (
    rae_uid, 
    sme_uid, 
    rae_name, 
    rae_code, 
    last_message, 
    last_message_at,
    unread_count,
    is_resolved
  )
  VALUES (
    v_rae_uid,
    v_sme_uid,
    v_rae_name,
    'RAE-HYD-001',
    'I need guidance on fertilizer selection',
    NOW() - INTERVAL '2 hours',
    2,
    false
  )
  RETURNING id INTO v_conversation_id;

  -- Insert sample messages
  INSERT INTO messages (conversation_id, sender_uid, sender_name, sender_role, content, is_read, created_at)
  VALUES
    -- RAE sends first message
    (v_conversation_id, v_rae_uid, v_rae_name, 'RAE', 'Hello! I need help with fertilizer recommendations for cotton crops.', true, NOW() - INTERVAL '2 hours'),
    
    -- SME replies
    (v_conversation_id, v_sme_uid, v_sme_name, 'SME', 'Hi Ramesh! I can help you with that. What is the current stage of your cotton crop?', true, NOW() - INTERVAL '1 hour 55 minutes'),
    
    -- RAE responds
    (v_conversation_id, v_rae_uid, v_rae_name, 'RAE', 'The cotton is at flowering stage. Soil is clayey and pH is around 7.5.', true, NOW() - INTERVAL '1 hour 50 minutes'),
    
    -- SME provides advice
    (v_conversation_id, v_sme_uid, v_sme_name, 'SME', 'For flowering stage cotton in clayey soil with pH 7.5, I recommend NPK 10-26-26 fertilizer. Apply 50kg per acre. Also consider adding potassium sulfate for better boll development.', true, NOW() - INTERVAL '1 hour 45 minutes'),
    
    -- RAE asks follow-up
    (v_conversation_id, v_rae_uid, v_rae_name, 'RAE', 'Thank you! What about pest control? I noticed some whiteflies yesterday.', false, NOW() - INTERVAL '1 hour 40 minutes'),
    
    -- SME responds (unread)
    (v_conversation_id, v_sme_uid, v_sme_name, 'SME', 'For whiteflies, spray Neem oil pesticide (2ml per liter) in the evening. Repeat after 7 days if needed. Also maintain field hygiene.', false, NOW() - INTERVAL '30 minutes');

  RAISE NOTICE 'Created conversation ID: %', v_conversation_id;
  RAISE NOTICE 'Added 6 sample messages';
END $$;

-- ============================================================
-- QUICK TEST QUERY
-- ============================================================
-- After running the above, check if data was created:

-- List all conversations
-- SELECT id, rae_name, rae_code, last_message, unread_count FROM conversations ORDER BY last_message_at DESC;

-- List all messages for a conversation (replace conversation_id)
-- SELECT sender_name, sender_role, content, is_read, created_at FROM messages WHERE conversation_id = 'YOUR_CONVERSATION_ID' ORDER BY created_at;

-- ============================================================
-- ALTERNATIVE: Manual Insert (if DO $$ block doesn't work)
-- ============================================================
-- 1. First, get your actual UIDs:
-- SELECT uid, name, role FROM profiles WHERE role IN ('RAE', 'SME');

-- 2. Insert a conversation (REPLACE THE UIDS):
-- INSERT INTO conversations (rae_uid, sme_uid, rae_name, rae_code, last_message, unread_count)
-- VALUES ('your-rae-uid', 'your-sme-uid', 'Ramesh Kumar', 'RAE-HYD-001', 'I need guidance', 2)
-- RETURNING id;

-- 3. Copy the returned ID, then insert messages (REPLACE conversation_id):
-- INSERT INTO messages (conversation_id, sender_uid, sender_name, sender_role, content)
-- VALUES 
--   ('conversation-id-here', 'rae-uid', 'Ramesh Kumar', 'RAE', 'Hello! I need help with fertilizers.'),
--   ('conversation-id-here', 'sme-uid', 'District Advisor', 'SME', 'Sure! What crop are you working with?');
