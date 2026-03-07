# FCM Integration - Step-by-Step Checklist ✅

Follow these steps in order to integrate Firebase Cloud Messaging.

---

## ✅ Step 1: Install Dependencies (DONE!)

Already added to pubspec.yaml:
- ✅ `firebase_messaging: ^15.1.5`
- ✅ `flutter_local_notifications: ^18.0.1`
- ✅ `http: ^1.2.2`

**Action**: Run this command:
```bash
flutter pub get
```

---

## ✅ Step 2: Database Migration (DONE!)

The migration file `SUPABASE_MIGRATION_FCM.sql` is ready.

**Action**: 
1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Go to SQL Editor
3. Copy contents of `SUPABASE_MIGRATION_FCM.sql`
4. Click "Run"
5. Verify: `SELECT fcm_token FROM profiles LIMIT 1;` (should see column)

---

## ✅ Step 3: Android Permissions (DONE!)

Already updated `android/app/src/main/AndroidManifest.xml` with FCM permissions.

**Action**: No action needed - already configured!

---

## ✅ Step 4: Service Files Created (DONE!)

Already created:
- ✅ `lib/services/notification_service.dart` - Handles receiving notifications
- ✅ `lib/services/fcm_sender_service.dart` - Sends notifications

**Action**: Update FCM Server Key (see Step 5 below)

---

## 🔑 Step 5: Get Firebase Server Key (REQUIRED!)

**Action**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your TRA FPCL project
3. Click ⚙️ **Project Settings**
4. Go to **Cloud Messaging** tab
5. Scroll to **Cloud Messaging API (Legacy)**
6. Copy the **Server key**
7. Open `lib/services/fcm_sender_service.dart`
8. Replace line 7:
   ```dart
   static const String _fcmServerKey = 'PASTE_YOUR_KEY_HERE';
   ```

⚠️ **Important**: This step is mandatory! Notifications won't work without the server key.

---

## 📝 Step 6: Update main.dart

**Action**: Add FCM initialization to `lib/main.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Add this function at top-level (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('📨 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // ADD THESE TWO LINES:
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

---

## 💬 Step 7: Add Chat Notifications

**Action**: Update `lib/screens/chat/chat_screen.dart`

Add import at top:
```dart
import '../../services/fcm_sender_service.dart';
```

In `_sendMessage()` method, after inserting message, add:
```dart
// Determine receiver
final receiverUid = _currentUserRole == 'rae' 
    ? (await _getConversation())['sme_uid'] 
    : widget.raeUid;

if (receiverUid != null) {
  FCMSenderService.sendChatNotification(
    receiverUid: receiverUid,
    senderName: _currentUserName,
    message: content,
    conversationId: widget.conversationId,
  );
}
```

Add helper method:
```dart
Future<Map<String, dynamic>> _getConversation() async {
  return await _supabase
      .from('conversations')
      .select('sme_uid')
      .eq('id', widget.conversationId)
      .single();
}
```

📄 **See**: FCM_QUICK_REFERENCE.md for exact code placement

---

## 🔔 Step 8: Add Advisory Request Notifications

**Action**: Update `lib/screens/rae/request_advisory_screen.dart`

Add import at top:
```dart
import '../../services/fcm_sender_service.dart';
```

In `_sendRequest()` method, after creating conversation, add:
```dart
await FCMSenderService.sendAdvisoryRequestNotification(
  raeUid: user.uid,
  raeName: raeName,
  district: raeDistrict,
  topic: _topicController.text.trim(),
  conversationId: conversationId,
);
```

📄 **See**: FCM_QUICK_REFERENCE.md section 2

---

## ✅ Step 9: Add Advisory Accepted Notifications

**Action**: Update `lib/screens/dashboard/sme_dashboard.dart`

Add import at top:
```dart
import '../../services/fcm_sender_service.dart';
```

In `_acceptRequest()` method, after accepting, add:
```dart
final smeProfile = await _smeService.getSmeProfile(_smeUid);
final smeName = smeProfile['name'] ?? 'SME Advisor';

await FCMSenderService.sendAdvisoryAcceptedNotification(
  raeUid: request.raeUid,
  smeName: smeName,
  conversationId: request.id,
);
```

📄 **See**: FCM_QUICK_REFERENCE.md section 3

---

## 📦 Step 10: Add Order Dispatch Notifications

**Action**: In your admin order dispatch code, add:

```dart
import '../services/fcm_sender_service.dart';

// After updating order status to 'dispatched'
await FCMSenderService.sendOrderDispatchNotification(
  raeUid: order['rae_uid'],
  orderId: orderId,
  productName: productName,
);
```

📄 **See**: FCM_QUICK_REFERENCE.md section 4

---

## 🚪 Step 11: Clear Token on Logout

**Action**: In your logout method (likely in auth_service.dart), add:

```dart
import 'notification_service.dart';

Future<void> signOut() async {
  await NotificationService().clearToken();  // Add this line
  await FirebaseAuth.instance.signOut();
}
```

---

## 🧪 Step 12: Test!

### Initial Test:
1. Run: `flutter run`
2. Check console for: `✅ Notification permission granted`
3. Check console for: `📱 FCM Token: ...`
4. Verify in Supabase: `SELECT uid, fcm_token FROM profiles;`

### Chat Notification Test:
1. Open app on Device A (RAE)
2. Open app on Device B (SME) in same conversation
3. Close/minimize app on Device B
4. Send message from Device A
5. Device B should show notification 🔔

### Advisory Request Test:
1. Open app as RAE
2. Create advisory request
3. Check SME devices - should all get notifications

### Order Dispatch Test:
1. From admin, dispatch an order
2. RAE who placed order should get notification

---

## 📊 Monitoring

### Check FCM Tokens in Database:
```sql
SELECT 
  uid,
  name,
  role,
  SUBSTRING(fcm_token, 1, 20) || '...' as token
FROM profiles 
WHERE fcm_token IS NOT NULL;
```

### Firebase Console Stats:
- Go to Firebase Console > Cloud Messaging
- View delivery statistics
- Check for failed sends

---

## 🐛 Troubleshooting

### No FCM token in logs?
- Notification permission denied by user
- App not connected to internet
- Firebase not initialized

### Token saved but no notifications?
- Check FCM Server Key is correct
- Verify receiver has FCM token
- Test on physical device (not emulator)

### Notifications work in foreground but not background?
- Check `_firebaseMessagingBackgroundHandler` is set up
- Verify notification channel is created
- Check app has battery optimization disabled

---

## ✅ Summary Checklist

Before testing, verify all these are done:

- [ ] Ran `flutter pub get`
- [ ] Ran `SUPABASE_MIGRATION_FCM.sql` in Supabase
- [ ] Got FCM Server Key from Firebase Console
- [ ] Pasted server key in `fcm_sender_service.dart`
- [ ] Updated `main.dart` with FCM initialization
- [ ] Added chat notification calls
- [ ] Added advisory request notification calls  
- [ ] Added advisory accepted notification calls
- [ ] Added order dispatch notification calls
- [ ] Added clear token on logout
- [ ] Tested on physical device

---

## 📚 Documentation Files

- **FCM_INTEGRATION_GUIDE.md** - Complete detailed guide
- **FCM_QUICK_REFERENCE.md** - Code snippets for each integration point
- **SUPABASE_MIGRATION_FCM.sql** - Database migration
- **This file** - Step-by-step checklist

---

**Time Estimate**: ~30 minutes to complete all steps

**Ready to start? Begin with Step 5 (Getting FCM Server Key)!** 🚀
