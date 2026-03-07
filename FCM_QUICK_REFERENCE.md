# FCM Integration - Quick Reference

## Where to Add Notification Calls

This document shows exactly where to add FCM notification calls in your existing code.

---

## 1. Chat Message Notifications

### File: `lib/screens/chat/chat_screen.dart`

Add import at the top:
```dart
import '../../services/fcm_sender_service.dart';
```

In the `_sendMessage()` method, add notification call after inserting message:

```dart
Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  final content = _messageController.text.trim();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  try {
    // Insert message
    await _supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_uid': uid,
      'sender_name': _currentUserName,
      'sender_role': _currentUserRole,
      'content': content,
      'is_read': false,
    });

    // Update conversation last message
    await _supabase.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', widget.conversationId);

    // ✨ ADD THIS: Send notification to receiver ✨
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

    _messageController.clear();
  } catch (e) {
    print('Error: $e');
  }
}

// Helper to get conversation details
Future<Map<String, dynamic>> _getConversation() async {
  return await _supabase
      .from('conversations')
      .select('sme_uid')
      .eq('id', widget.conversationId)
      .single();
}
```

---

## 2. Advisory Request Notifications

### File: `lib/screens/rae/request_advisory_screen.dart`

Add import at the top:
```dart
import '../../services/fcm_sender_service.dart';
```

In the `_sendRequest()` method, add notification after creating conversation:

```dart
Future<void> _sendRequest() async {
  // ... existing validation code ...

  try {
    // Get RAE profile
    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select('name, district')
        .eq('uid', user.uid)
        .single();

    final raeName = profileResponse['name'] as String? ?? 'RAE';
    final raeDistrict = profileResponse['district'] as String? ?? '';

    // Create pending conversation
    final response = await Supabase.instance.client
        .from('conversations')
        .insert({
          'rae_uid': user.uid,
          'sme_uid': null,
          'rae_name': raeName,
          'rae_code': user.phoneNumber ?? '',
          'rae_district': raeDistrict,
          'status': 'pending',
          'last_message': _topicController.text.trim(),
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    final conversationId = response['id'] as String;

    // ✨ ADD THIS: Notify all district SMEs ✨
    await FCMSenderService.sendAdvisoryRequestNotification(
      raeUid: user.uid,
      raeName: raeName,
      district: raeDistrict,
      topic: _topicController.text.trim(),
      conversationId: conversationId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Advisory request sent!')),
    );
    Navigator.of(context).pop();
  } catch (e) {
    // ... error handling ...
  }
}
```

---

## 3. Advisory Accepted Notifications

### File: `lib/screens/dashboard/sme_dashboard.dart`

Add import at the top:
```dart
import '../../services/fcm_sender_service.dart';
```

In the `_acceptRequest()` method, add notification after accepting:

```dart
Future<void> _acceptRequest(ConversationItem request) async {
  try {
    // Accept the request
    await _smeService.acceptAdvisoryRequest(
      conversationId: request.id,
      smeUid: _smeUid,
    );

    // ✨ ADD THIS: Get SME name and notify RAE ✨
    final smeProfile = await _smeService.getSmeProfile(_smeUid);
    final smeName = smeProfile['name'] ?? 'SME Advisor';
    
    await FCMSenderService.sendAdvisoryAcceptedNotification(
      raeUid: request.raeUid,
      smeName: smeName,
      conversationId: request.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Request accepted!')),
    );

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: request.id,
          raeName: request.raeName,
          raeCode: request.raeCode,
          raeUid: request.raeUid,
        ),
      ),
    );
  } catch (e) {
    // ... error handling ...
  }
}
```

---

## 4. Order Dispatch Notifications

### File: Admin order management (wherever you handle order status updates)

Add import at the top:
```dart
import '../services/fcm_sender_service.dart';
```

When updating order status to 'dispatched':

```dart
Future<void> _dispatchOrder(String orderId) async {
  try {
    // Update order status
    await Supabase.instance.client
        .from('orders')
        .update({
          'status': 'dispatched',
          'dispatched_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    // Get order details for notification
    final order = await Supabase.instance.client
        .from('orders')
        .select('''
          id,
          rae_uid,
          order_items (
            product:products (
              name
            )
          )
        ''')
        .eq('id', orderId)
        .single();

    final raeUid = order['rae_uid'] as String;
    final items = order['order_items'] as List;
    final productName = items.isNotEmpty 
        ? items[0]['product']['name'] as String 
        : 'Products';

    // ✨ ADD THIS: Notify RAE ✨
    await FCMSenderService.sendOrderDispatchNotification(
      raeUid: raeUid,
      orderId: orderId,
      productName: productName,
    );

    print('✅ Order dispatched and notification sent');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 5. Initialize FCM in Main App

### File: `lib/main.dart`

Update your main function:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('📨 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // ✨ ADD THIS: Set up FCM background handler ✨
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // ✨ ADD THIS: Initialize notification service ✨
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

---

## 6. Clear Token on Logout

### File: `lib/services/auth_service.dart` (or wherever you handle logout)

Add to your logout method:

```dart
import 'notification_service.dart';

Future<void> signOut() async {
  try {
    // ✨ ADD THIS: Clear FCM token before logout ✨
    await NotificationService().clearToken();
    
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();
    
    print('✅ Signed out successfully');
  } catch (e) {
    print('Error signing out: $e');
  }
}
```

---

## Testing Checklist

After adding all the above code:

1. ✅ Run `flutter pub get` to install new dependencies
2. ✅ Run SUPABASE_MIGRATION_FCM.sql in Supabase SQL Editor
3. ✅ Update AndroidManifest.xml (see FCM_INTEGRATION_GUIDE.md)
4. ✅ Get FCM Server Key from Firebase Console
5. ✅ Paste server key in `fcm_sender_service.dart` line 7
6. ✅ Run app: `flutter run`
7. ✅ Check logs for "FCM Token: ..." message
8. ✅ Verify token is saved in Supabase profiles table
9. ✅ Test chat notification (send message, receiver should get notified)
10. ✅ Test advisory request (RAE creates request, SMEs get notified)
11. ✅ Test advisory accepted (SME accepts, RAE gets notified)
12. ✅ Test order dispatch (admin dispatches order, RAE gets notified)

---

## Common Issues

**"No FCM token found"**
- User hasn't granted notification permission
- App hasn't initialized FCM yet
- Check: `SELECT fcm_token FROM profiles WHERE uid = 'USER_UID';`

**Notification not appearing**
- Verify FCM server key is correct
- Check device internet connection
- Test on physical device (emulator unreliable)
- Look for error logs in console

**Token not saved to database**
- Check if profiles table has fcm_token column
- Verify user is logged in when FCM initializes
- Check Supabase connection

---

## Next Steps

1. Test all notification scenarios
2. Customize notification sounds/icons
3. Add notification navigation (tap to open specific screen)
4. Implement notification preferences (let users toggle types)
5. Add notification badges on app icon

---

📚 **Full documentation**: See FCM_INTEGRATION_GUIDE.md for complete details.
