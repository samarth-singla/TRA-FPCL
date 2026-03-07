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
        // TODO: Add navigation logic here
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
    
    // TODO: Implement navigation based on notification type
    if (type == 'chat_message') {
      // Navigate to chat screen
      print('Navigate to chat: ${data['conversation_id']}');
      // Add: Navigator.push(context, MaterialPageRoute(...))
    } else if (type == 'order_dispatched') {
      // Navigate to order tracking
      print('Navigate to order: ${data['order_id']}');
      // Add: Navigator.push(context, MaterialPageRoute(...))
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
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.notification?.title}');
}
