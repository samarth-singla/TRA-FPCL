# Firebase Cloud Messaging (FCM) Integration Guide

## Overview
This guide will help you integrate FCM for push notifications in your TRA FPCL app. We'll implement notifications for:
1. **Chat messages** (when RAE/SME receives a new message)
2. **Order dispatch updates** (when order status changes to 'dispatched')

---

## 📦 Step 1: Add Dependencies

Add FCM package to `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^15.1.5  # Add this line
  flutter_local_notifications: ^18.0.1  # For foreground notifications
```

Then run:
```bash
flutter pub get
```

---

## 🔧 Step 2: Android Configuration

### 2.1 Update `android/app/src/main/AndroidManifest.xml`

Add these permissions and service inside `<application>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions before <application> -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="tra_fpcl_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add this inside <application> -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
        
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.messaging.INSTANCE_ID_EVENT"/>
            </intent-filter>
        </service>
        
        <!-- Rest of your existing config -->
    </application>
</manifest>
```

---

## 🗄️ Step 3: Update Supabase Database

Add FCM token storage to profiles table:

```sql
-- Run this in Supabase SQL Editor
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token);
```

---

## 📱 Step 4: Request Notification Permission

### Create `lib/services/notification_service.dart`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and request permission
  Future<void> initialize() async {
    // Request permission (iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
      
      // Initialize local notifications for foreground
      await _initializeLocalNotifications();
      
      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      // Save token to Supabase
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }
      
      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFCMToken);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
      
      // Handle notification when app is terminated and opened via notification
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleMessageClick(message);
        }
      });
      
    } else {
      print('❌ Notification permission denied');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Save FCM token to Supabase profiles table
  Future<void> _saveFCMToken(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('uid', uid);
      
      _fcmToken = token;
      print('💾 FCM token saved to Supabase');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received: ${message.notification?.title}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification click (navigate to appropriate screen)
  void _handleMessageClick(RemoteMessage message) {
    print('🔔 Notification clicked: ${message.data}');
    
    final data = message.data;
    final type = data['type'] as String?;
    
    // TODO: Navigate based on notification type
    // You'll implement this after setting up notification routing
    if (type == 'chat_message') {
      // Navigate to chat screen
      print('Navigate to chat: ${data['conversation_id']}');
    } else if (type == 'order_dispatched') {
      // Navigate to order tracking
      print('Navigate to order: ${data['order_id']}');
    }
  }

  /// Clear FCM token on logout
  Future<void> clearToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('uid', uid);
      
      await _fcm.deleteToken();
      _fcmToken = null;
      print('🗑️ FCM token cleared');
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.notification?.title}');
}
```

---

## 🚀 Step 5: Initialize FCM in `lib/main.dart`

Update your `main()` function:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
  
  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const MyApp());
}
```

---

## 📤 Step 6: Send Notifications from Backend

You have two options:

### Option A: Supabase Edge Functions (Recommended)

Create a Supabase Edge Function to send FCM notifications:

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!

serve(async (req) => {
  const { fcm_token, title, body, data } = await req.json()

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify({
      to: fcm_token,
      notification: {
        title: title,
        body: body,
        sound: 'default',
      },
      data: data,
      priority: 'high',
    }),
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

### Option B: Direct Flutter Implementation (Quick Testing)

Create `lib/services/fcm_sender_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMSenderService {
  // Get your FCM Server Key from Firebase Console > Project Settings > Cloud Messaging
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';
  
  /// Send chat notification to user
  static Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      // Get receiver's FCM token
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('uid', receiverUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for user');
        return;
      }
      
      // Send notification
      await _sendNotification(
        fcmToken: fcmToken,
        title: senderName,
        body: message,
        data: {
          'type': 'chat_message',
          'conversation_id': conversationId,
          'sender_name': senderName,
        },
      );
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }
  
  /// Send order dispatch notification to RAE
  static Future<void> sendOrderDispatchNotification({
    required String raeUid,
    required String orderId,
    required String productName,
  }) async {
    try {
      // Get RAE's FCM token
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('uid', raeUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for RAE');
        return;
      }
      
      // Send notification
      await _sendNotification(
        fcmToken: fcmToken,
        title: 'Order Dispatched! 📦',
        body: 'Your order for $productName has been dispatched',
        data: {
          'type': 'order_dispatched',
          'order_id': orderId,
        },
      );
    } catch (e) {
      print('❌ Error sending order notification: $e');
    }
  }
  
  /// Internal method to send FCM notification
  static Future<void> _sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data,
          'priority': 'high',
          'android': {
            'notification': {
              'channel_id': 'high_importance_channel',
            },
          },
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Notification sent successfully');
      } else {
        print('❌ FCM error: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM: $e');
    }
  }
}
```

---

## 💬 Step 7: Integrate Chat Notifications

Update your chat message sending code to send notifications:

```dart
// In lib/screens/chat/chat_screen.dart
import '../../services/fcm_sender_service.dart';

Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  final content = _messageController.text.trim();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  try {
    // Send message to Supabase
    await _supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_uid': uid,
      'sender_name': _currentUserName,
      'sender_role': _currentUserRole,
      'content': content,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update conversation
    await _supabase.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
      'unread_count': _supabase.rpc('increment', {'x': 1}),
    }).eq('id', widget.conversationId);

    // ✨ SEND NOTIFICATION ✨
    final receiverUid = _currentUserRole == 'rae' 
        ? (await _getSmeUid()) 
        : widget.raeUid;
    
    await FCMSenderService.sendChatNotification(
      receiverUid: receiverUid,
      senderName: _currentUserName,
      message: content,
      conversationId: widget.conversationId,
    );

    _messageController.clear();
  } catch (e) {
    print('Error sending message: $e');
  }
}
```

---

## 📦 Step 8: Integrate Order Dispatch Notifications

Add notification when admin dispatches an order:

```dart
// In your admin order management code
import '../services/fcm_sender_service.dart';

Future<void> _dispatchOrder(String orderId) async {
  try {
    // Update order status
    await _supabase.from('orders').update({
      'status': 'dispatched',
      'dispatched_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    // Get order details
    final order = await _supabase
        .from('orders')
        .select('rae_uid, order_items(product:products(name))')
        .eq('id', orderId)
        .single();
    
    final raeUid = order['rae_uid'] as String;
    final productName = order['order_items'][0]['product']['name'] as String;

    // ✨ SEND NOTIFICATION ✨
    await FCMSenderService.sendOrderDispatchNotification(
      raeUid: raeUid,
      orderId: orderId,
      productName: productName,
    );
    
    print('✅ Order dispatched and notification sent');
  } catch (e) {
    print('❌ Error dispatching order: $e');
  }
}
```

---

## 🔑 Step 9: Get Firebase Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Project Settings** (gear icon)
4. Go to **Cloud Messaging** tab
5. Scroll down to **Cloud Messaging API (Legacy)**
6. Copy the **Server key**
7. Paste it in `FCMSenderService._fcmServerKey`

⚠️ **Security Warning**: Never commit the server key to Git! Use environment variables or Supabase Secrets for production.

---

## 🧪 Testing

### Test Chat Notifications:
1. Run app on Device A (logged in as RAE)
2. Run app on Device B (logged in as SME)
3. Send message from Device A
4. Device B should receive notification (even if app is in background)

### Test Order Dispatch Notifications:
1. Run app as RAE
2. From admin panel, dispatch an order assigned to that RAE
3. RAE device should receive notification

### Debug Tips:
- Check Logcat/Console for FCM token
- Verify token is saved in Supabase profiles table
- Test with app in foreground, background, and killed states
- Check Firebase Console > Cloud Messaging for delivery stats

---

## 📋 Checklist

- [ ] Add `firebase_messaging` and `flutter_local_notifications` dependencies
- [ ] Update `AndroidManifest.xml` with permissions and FCM config
- [ ] Run SQL migration to add `fcm_token` column
- [ ] Create `notification_service.dart`
- [ ] Update `main.dart` to initialize FCM
- [ ] Get FCM Server Key from Firebase Console
- [ ] Create `fcm_sender_service.dart` with server key
- [ ] Integrate chat notifications
- [ ] Integrate order dispatch notifications
- [ ] Test on physical device (notifications don't work on emulator reliably)
- [ ] Update logout logic to clear FCM token

---

## 🚀 Next Steps

1. **Implement notification navigation**: When user taps notification, navigate to the specific chat or order screen
2. **Add notification badges**: Show unread count on app icon
3. **Customize notification sounds**: Use different sounds for chat vs orders
4. **Add notification preferences**: Let users control which notifications they receive
5. **Production security**: Move FCM server key to Supabase Edge Function or secure backend

---

## 🐛 Common Issues

### Notifications not appearing:
- Check FCM token is saved in database
- Verify server key is correct
- Test on physical device (not emulator)
- Check notification permission is granted

### Background notifications not working:
- Ensure `onBackgroundMessage` handler is configured
- Check Android notification channel is created
- Verify app has battery optimization disabled

### Token null:
- Call `initialize()` after Firebase.initializeApp()
- Check internet connection
- Request permission explicitly

---

## 📚 Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)

---

**Ready to implement? Run the checklist step-by-step and test thoroughly!** 🎉
