# 🔔 FCM Deployment Guide (After Blaze Plan Upgrade)

This guide walks you through deploying Firebase Cloud Messaging after upgrading to Firebase Blaze plan.

---

## ✅ Current Status

**Already Completed:**
- ✅ FCM packages added to Flutter app (`firebase_messaging`, `flutter_local_notifications`)
- ✅ Notification services implemented (`notification_service.dart`, `fcm_sender_service.dart`)
- ✅ Firebase Cloud Functions code written and validated (`functions/src/index.ts`)
- ✅ Android permissions configured (`AndroidManifest.xml`)
- ✅ Main.dart initialized with FCM handlers
- ✅ Database migration file created (`SUPABASE_MIGRATION_FCM.sql`)

**Blocked (Requires Blaze Plan):**
- ⚠️ Deploy Cloud Functions to Firebase
- ⚠️ Enable Firebase Cloud Messaging API

---

## 📋 Step-by-Step Deployment

### Step 1: Upgrade to Firebase Blaze Plan

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/project/tra-fpcl-33738/usage/details

2. **Upgrade to Blaze Plan:**
   - Click **"Upgrade"** button
   - Select **"Blaze Plan"** (pay-as-you-go)
   - Add your **credit card** information
   - Complete the upgrade

3. **Free Tier Limits (You likely won't exceed these):**
   - Cloud Functions: **2 million invocations/month** FREE
   - Compute: **400,000 GB-seconds/month** FREE
   - Outbound networking: **5 GB/month** FREE
   - Cloud Messaging: **Unlimited** FREE

> **Note:** Your app likely won't exceed the free tier limits. You'll only pay if you have very high traffic.

---

### Step 2: Deploy Firebase Cloud Functions

1. **Open Terminal in Project Root:**
   ```powershell
   cd "C:\Users\Lenovo\Desktop\local fpcl\tra_fpcl_app"
   ```

2. **Navigate to Functions Folder:**
   ```powershell
   cd functions
   ```

3. **Deploy Functions:**
   ```powershell
   firebase deploy --only functions
   ```

4. **Wait for Deployment (2-5 minutes):**
   - You'll see progress logs
   - Functions being built and deployed
   - URLs for each function will be displayed

5. **Verify Deployment:**
   - Go to: https://console.firebase.google.com/project/tra-fpcl-33738/functions
   - You should see 4 functions:
     - `sendChatNotification`
     - `sendAdvisoryNotification`
     - `sendAdvisoryAcceptedNotification`
     - `sendOrderNotification`

---

### Step 3: Enable Firebase Cloud Messaging API

1. **Open Google Cloud Console:**
   - Go to: https://console.cloud.google.com/apis/library/fcm.googleapis.com?project=tra-fpcl-33738

2. **Enable the API:**
   - Click **"Enable"** button
   - Wait for confirmation (30 seconds)

3. **Verify API is Enabled:**
   - Go to: https://console.cloud.google.com/apis/dashboard?project=tra-fpcl-33738
   - Search for "Firebase Cloud Messaging API"
   - Status should show **"Enabled"**

---

### Step 4: Run Database Migration

1. **Open Supabase Dashboard:**
   - Go to: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/editor

2. **Open SQL Editor:**
   - Click **"SQL Editor"** in left sidebar
   - Click **"New query"**

3. **Run Migration:**
   - Copy the contents of `SUPABASE_MIGRATION_FCM.sql`
   - Paste into SQL Editor
   - Click **"Run"** button

4. **Verify Migration:**
   - Go to **Table Editor** → **profiles** table
   - You should see new column: `fcm_token` (TEXT, nullable)

---

### Step 5: Update Flutter App Dependencies

1. **Get Latest Packages:**
   ```powershell
   flutter pub get
   ```

2. **Clean Build:**
   ```powershell
   flutter clean
   flutter pub get
   ```

---

### Step 6: Integrate Notification Calls in Code

You need to add notification calls in 4 places:

#### 6.1 Chat Notifications

**File:** `lib/screens/chat/chat_screen.dart` (or equivalent)

**Location:** In the `_sendMessage()` method, after successfully inserting the message

```dart
import '../services/fcm_sender_service.dart';

// After message is successfully inserted to Supabase
await FCMSenderService.sendChatNotification(
  receiverUid: receiverUserId,  // UID of message receiver
  senderName: currentUserName,   // Name of person sending message
  messageText: messageText,      // Preview of message content
);
```

#### 6.2 Advisory Request Notifications

**File:** `lib/screens/rae/request_advisory_screen.dart` (or equivalent)

**Location:** After RAE creates a new advisory request

```dart
import '../../services/fcm_sender_service.dart';

// After conversation is created
await FCMSenderService.sendAdvisoryRequestNotification(
  requestId: conversationId,
  raeName: raeUserName,
  district: selectedDistrict,  // e.g., "Jalandhar"
  cropType: selectedCrop,      // e.g., "wheat"
);
```

#### 6.3 Advisory Acceptance Notifications

**File:** `lib/screens/dashboard/sme_dashboard.dart` (or equivalent)

**Location:** After SME accepts an advisory request

```dart
import '../../services/fcm_sender_service.dart';

// After accepting the advisory request
await FCMSenderService.sendAdvisoryAcceptedNotification(
  raeUid: raeUserId,
  smeName: smeUserName,
  requestId: advisoryRequestId,
);
```

#### 6.4 Order Dispatch Notifications

**File:** Where admin updates order status to 'dispatched'

**Location:** After order status is updated to 'dispatched'

```dart
import '../services/fcm_sender_service.dart';

// After order status changed to 'dispatched'
await FCMSenderService.sendOrderDispatchNotification(
  raeUid: raeUserId,
  orderId: orderId,
  productName: productName,  // e.g., "NPK Fertilizer 50kg"
);
```

---

### Step 7: Update Logout to Clear FCM Token

**File:** `lib/services/auth_service.dart`

**Location:** In the `signOut()` method, before Firebase logout

```dart
import 'notification_service.dart';

Future<void> signOut() async {
  // Clear FCM token before logout
  await NotificationService().clearToken();
  
  // Existing logout code
  await _auth.signOut();
  // ... rest of your signOut logic
}
```

---

### Step 8: Test Notifications on Physical Device

> **Important:** Notifications are unreliable on emulators. Use a physical device.

1. **Run App on Physical Device:**
   ```powershell
   flutter run
   ```

2. **Check Console Logs:**
   - Look for: `📱 FCM Token: ...`
   - Look for: `✅ Notification permission granted`

3. **Verify Token in Database:**
   - Open Supabase → Table Editor → `profiles`
   - Find your user's row
   - Check `fcm_token` column has a value

4. **Test Chat Notification:**
   - Login as User A
   - Send message to User B
   - User B should receive notification (even if app is closed/background)

5. **Test Advisory Notification:**
   - Login as RAE
   - Create advisory request
   - All SMEs in that district should receive notification

6. **Test Advisory Acceptance:**
   - Login as SME
   - Accept an advisory request
   - RAE should receive notification

7. **Test Order Dispatch:**
   - Login as Admin
   - Dispatch an order
   - RAE should receive notification

---

## 🐛 Troubleshooting

### Deployment Issues

**Error: "Cannot find module 'firebase-functions'"**
- Solution: Run `cd functions && npm install`

**Error: "ESLint errors blocking deployment"**
- Solution: Run `cd functions && npm run lint` to check errors
- Fix any errors and redeploy

**Error: "Permission denied"**
- Solution: Run `firebase login` to re-authenticate

### Notification Issues

**Notifications not received:**
1. Check device has internet connection
2. Verify FCM token is saved in database (`profiles.fcm_token`)
3. Check Firebase Console → Cloud Messaging for delivery stats
4. Test on physical device (not emulator)
5. Check app has notification permissions (Settings → Apps → Your App → Notifications)

**Token is null:**
1. Ensure `NotificationService().initialize()` is called in `main.dart`
2. Check Android permissions in `AndroidManifest.xml`
3. Restart app after granting permissions

**Foreground notifications not showing:**
1. Check `flutter_local_notifications` is properly initialized
2. Verify notification channel is created (`high_importance_channel`)
3. Check device notification settings

---

## 📊 Monitoring

### Firebase Console

**Cloud Functions Logs:**
- Go to: https://console.firebase.google.com/project/tra-fpcl-33738/functions/logs
- See function invocations, errors, and execution times

**Cloud Messaging Stats:**
- Go to: https://console.firebase.google.com/project/tra-fpcl-33738/notification
- See delivery rates, opened notifications, etc.

**Billing & Usage:**
- Go to: https://console.firebase.google.com/project/tra-fpcl-33738/usage
- Monitor function invocations and costs

---

## 🎯 Success Criteria

You'll know FCM is working when:

- ✅ Firebase Cloud Functions deployed successfully
- ✅ Firebase Cloud Messaging API enabled
- ✅ Database has `fcm_token` column
- ✅ App logs show FCM token on startup
- ✅ Tokens are saved in Supabase `profiles` table
- ✅ Chat notifications arrive on receiver's device
- ✅ Advisory notifications send to all district SMEs
- ✅ RAE receives notification when SME accepts
- ✅ RAE receives notification when order dispatched

---

## 📚 Additional Resources

- [FCM_INTEGRATION_GUIDE.md](FCM_INTEGRATION_GUIDE.md) - Detailed technical documentation
- [FCM_QUICK_REFERENCE.md](FCM_QUICK_REFERENCE.md) - Quick code snippets
- [FCM_CHECKLIST.md](FCM_CHECKLIST.md) - Implementation checklist
- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM HTTP v1 API Documentation](https://firebase.google.com/docs/cloud-messaging/http-server-ref)

---

## 💰 Cost Estimation

**Expected Monthly Costs:**

| Resource | Free Tier | Your Estimated Usage | Cost |
|----------|-----------|---------------------|------|
| Cloud Functions Invocations | 2M/month | ~10,000/month | $0.00 |
| Cloud Functions Compute | 400K GB-sec | ~5K GB-sec | $0.00 |
| FCM Messages | Unlimited | Unlimited | $0.00 |
| **Total** | - | - | **$0.00** |

> **Note:** Unless you have thousands of active users sending thousands of notifications, you'll stay within the free tier.

---

## ⚠️ Before Going to Production

1. **Remove Test Phone Numbers** from Firebase Console
2. **Enable SMS Authentication** for real users
3. **Set up Billing Alerts** in Google Cloud Console
4. **Test on Multiple Devices** (Android/iOS)
5. **Monitor Function Logs** for errors
6. **Add Error Handling** for failed notifications
7. **Implement Retry Logic** for network failures

---

## 🆘 Need Help?

If you encounter issues during deployment:

1. Check Firebase Console logs
2. Review error messages carefully
3. Verify all prerequisites are met
4. Test on physical device (not emulator)
5. Check Supabase database for token values

Common issues and solutions are in the Troubleshooting section above.

---

**Last Updated:** March 7, 2026  
**Firebase Project:** tra-fpcl-33738  
**Status:** Ready to deploy after Blaze upgrade
