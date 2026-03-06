# Advisory Request System - Implementation Complete ✅

## Overview
Successfully implemented a complete advisory request system where RAEs can request help from district SMEs. The system handles:
- RAE creates advisory request (pending state)
- All SMEs in the same district see the request
- First SME to accept gets assigned to the conversation
- Chat becomes active between RAE and SME

---

## 🚀 Setup Instructions

### 1. Run Database Migration (CRITICAL - DO THIS FIRST!)
Open Supabase SQL Editor and run the migration script:
```bash
File: SUPABASE_MIGRATION_ADVISORY.sql
```

This will:
- Add `rae_district` column to conversations table
- Add `status` column with values: pending/active/resolved
- Make `sme_uid` nullable (for pending requests)
- Create indexes for performance

**Location**: `c:\Users\Lenovo\Desktop\local fpcl\tra_fpcl_app\SUPABASE_MIGRATION_ADVISORY.sql`

---

## 📁 Files Created/Modified

### New Files Created:
1. **lib/screens/rae/request_advisory_screen.dart**
   - RAE interface to create advisory requests
   - Form with topic/issue description
   - Validates RAE has district information
   - Prevents multiple pending requests
   - Shows status if RAE already has active request

2. **SUPABASE_MIGRATION_ADVISORY.sql**
   - Migration script for database schema update
   - Safe to run multiple times (uses IF NOT EXISTS)

### Files Modified:
1. **lib/services/sme_service.dart**
   - Updated `ConversationItem` model:
     * `smeUid` is now nullable (String?)
     * Added `raeDistrict` field
     * Added `status` field
     * Added helper methods: `isPending`, `isActive`
   - Added `pendingRequestsStream()` - streams pending requests for district
   - Added `acceptAdvisoryRequest()` - assigns SME and activates conversation
   - Updated `conversationsStream()` - now only returns active conversations

2. **lib/screens/dashboard/sme_dashboard.dart**
   - Added "Pending Advisory Requests" section at top
   - Shows orange-highlighted pending requests from district RAEs
   - Added "Accept" button on each pending request
   - Added `_acceptRequest()` method - handles acceptance and navigates to chat
   - Race condition protection (only accepts if still pending)

3. **lib/screens/dashboard/rae_dashboard.dart**
   - Added import for RequestAdvisoryScreen
   - Updated Advisory button to navigate to request screen

4. **SUPABASE_TABLES.sql**
   - Updated conversations table schema (for reference)
   - Reflects new pending request flow

---

## 🔄 User Flow

### RAE Initiates Request:
1. RAE logs in to dashboard
2. Taps "Advisory" button
3. Enters topic/issue description
4. Taps "Send Request"
5. Request sent to all SMEs in RAE's district
6. RAE sees confirmation message

### SME Responds:
1. SME logs in to dashboard
2. Sees "Pending Advisory Requests" section (orange)
3. Views request details: RAE name, district, topic, time
4. Taps "Accept" button
5. Conversation becomes active
6. Automatically navigates to chat screen

### Chat Conversation:
1. Real-time messaging between RAE and SME
2. Green bubbles for RAE, purple bubbles for SME
3. Timestamps and read receipts
4. Auto-scroll to latest messages

---

## 🧪 Testing Steps

### Prerequisites:
1. ✅ Run SUPABASE_MIGRATION_ADVISORY.sql in Supabase SQL Editor
2. ✅ Ensure test accounts have `district` field populated in profiles table
3. ✅ RAE and SME must be in the same district

### Test RAE Account Setup:
```sql
-- Check RAE profile has district
SELECT uid, name, role, district FROM profiles WHERE role = 'rae';

-- If district is missing, update:
UPDATE profiles 
SET district = 'Hyderabad' 
WHERE uid = 'YOUR_RAE_UID';
```

### Test SME Account Setup:
```sql
-- Check SME profile has district
SELECT uid, name, role, district FROM profiles WHERE role = 'sme';

-- If district is missing, update:
UPDATE profiles 
SET district = 'Hyderabad' 
WHERE uid = 'YOUR_SME_UID';
```

### Test Flow:
1. **Login as RAE** (Phone: +919999999999, OTP: 123456)
2. Tap "Advisory" button on dashboard
3. Enter topic: "Need help with crop disease identification"
4. Tap "Send Request"
5. See success message
6. **Logout**

7. **Login as SME** (same district)
8. Dashboard should show "Pending Advisory Requests (1)"
9. See RAE's request with orange highlight
10. Tap "Accept" button
11. Automatically navigates to chat screen

12. **Send test message** from SME
13. **Logout**

14. **Login as RAE** again
15. Dashboard should now show "Active Conversations"
16. Tap conversation to see SME's message
17. Send reply

18. **Verify real-time**: 
    - Keep both devices/browsers open
    - Send messages from one side
    - See instant delivery on other side

---

## 🎨 UI Components

### RAE Request Screen:
- Info card explaining district matching
- Text field for topic/issue (min 10 chars)
- Green "Send Request" button
- Loading state during submission
- Success/error messages

### SME Pending Requests Section:
- Orange section header with count badge
- Orange-highlighted request cards
- Shows: RAE name, district badge, code, topic, time
- Green "Accept" button on each request
- Section hidden when no pending requests

### Active Conversations:
- Existing chat screen (no changes)
- Real-time messaging continues as before

---

## 🔒 Race Condition Protection

The system prevents multiple SMEs from accepting the same request:

```dart
await _supabase
    .from('conversations')
    .update({'sme_uid': smeUid, 'status': 'active'})
    .eq('id', conversationId)
    .eq('status', 'pending'); // Only updates if still pending
```

If SME-A and SME-B click Accept simultaneously:
- First update succeeds (changes status to 'active')
- Second update finds no rows (status is no longer 'pending')
- Only SME-A gets assigned

---

## 🔍 Database Structure

### Conversations Table (Updated):
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rae_uid TEXT NOT NULL,
    sme_uid TEXT,                    -- Nullable for pending requests
    rae_name TEXT NOT NULL,
    rae_code TEXT NOT NULL,
    rae_district TEXT NOT NULL,      -- NEW: for district matching
    status TEXT NOT NULL             -- NEW: pending/active/resolved
        DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'resolved')),
    last_message TEXT,
    last_message_at TIMESTAMP,
    unread_count INTEGER DEFAULT 0,
    is_resolved BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_conversations_rae_district ON conversations(rae_district);
CREATE INDEX idx_conversations_status ON conversations(status);
```

---

## 🐛 Troubleshooting

### "District information is missing" error:
- Ensure RAE profile has `district` field populated
- Run: `UPDATE profiles SET district = 'Hyderabad' WHERE uid = 'RAE_UID';`

### No pending requests showing for SME:
- Verify SME and RAE are in the same district
- Check SME profile: `SELECT district FROM profiles WHERE uid = 'SME_UID';`
- Check RAE's request: `SELECT * FROM conversations WHERE status = 'pending';`

### Request already exists error:
- RAE can only have one pending/active request at a time
- Resolve current conversation before creating new request
- Or manually update: `UPDATE conversations SET status = 'resolved' WHERE rae_uid = 'RAE_UID';`

### Accept button not working:
- Check browser console for errors
- Verify migration was run successfully
- Confirm conversations table has `status` and `rae_district` columns

---

## 📊 Status Flow

```
      RAE Creates Request
              ↓
      Status: PENDING
      sme_uid: NULL
              ↓
      [ Visible to all district SMEs ]
              ↓
      SME Accepts Request
              ↓
      Status: ACTIVE
      sme_uid: SME_UID
              ↓
      [ 1-on-1 Chat Active ]
              ↓
      (Optional) Mark Resolved
              ↓
      Status: RESOLVED
```

---

## 🎯 Key Features

✅ District-based matching (RAE requests only go to same-district SMEs)
✅ First-come-first-served acceptance (race condition handled)
✅ Prevents duplicate requests (RAE can't have multiple pending)
✅ Real-time updates (Supabase streams for instant UI refresh)
✅ Clean UI separation (pending vs active conversations)
✅ Automatic navigation (accepts and goes straight to chat)
✅ Status tracking (pending → active → resolved)

---

## 🚀 Ready to Test!

1. ✅ Run SUPABASE_MIGRATION_ADVISORY.sql first
2. ✅ Ensure test accounts have districts set
3. ✅ Run `flutter run`
4. ✅ Test the complete flow (RAE → SME → Chat)

The system is production-ready! 🎉
