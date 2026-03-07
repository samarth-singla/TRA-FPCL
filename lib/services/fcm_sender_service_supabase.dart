import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// FCM Notification Service using Supabase Edge Functions (FREE)
/// 
/// This version calls Supabase Edge Functions instead of Firebase Cloud Functions
/// No billing required!
class FCMSenderService {
  static final _supabase = Supabase.instance.client;
  
  /// Send chat notification to user via Supabase Edge Function
  static Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      // Get receiver's FCM token from database
      final profile = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('uid', receiverUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for user: $receiverUid');
        return;
      }
      
      // Call Supabase Edge Function
      final response = await http.post(
        Uri.parse('${_supabase.supabaseUrl}/functions/v1/send-fcm-notification'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'title': senderName,
          'body': message.length > 100 ? '${message.substring(0, 100)}...' : message,
          'data': {
            'type': 'chat_message',
            'conversation_id': conversationId,
            'sender_name': senderName,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Chat notification sent via Supabase Edge Function');
      } else {
        print('❌ Error: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }
  
  /// Send advisory request notification to all district SMEs
  static Future<void> sendAdvisoryRequestNotification({
    required String raeUid,
    required String raeName,
    required String district,
    required String topic,
    required String conversationId,
  }) async {
    try {
      // Get all SME tokens in district
      final smes = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('role', 'sme')
          .eq('district', district);
      
      final tokens = smes
          .map((s) => s['fcm_token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();
      
      if (tokens.isEmpty) {
        print('⚠️ No SMEs with FCM tokens in district: $district');
        return;
      }
      
      // Call Edge Function for each token
      for (final token in tokens) {
        await http.post(
          Uri.parse('${_supabase.supabaseUrl}/functions/v1/send-fcm-notification'),
          headers: {
            'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'fcmToken': token,
            'title': 'New Advisory Request 🔔',
            'body': '$raeName needs help: ${topic.length > 80 ? '${topic.substring(0, 80)}...' : topic}',
            'data': {
              'type': 'advisory_request',
              'conversation_id': conversationId,
              'rae_name': raeName,
              'district': district,
            },
          }),
        );
      }
      
      print('✅ Advisory notifications sent to ${tokens.length} SMEs');
    } catch (e) {
      print('❌ Error sending advisory notifications: $e');
    }
  }
  
  /// Send advisory accepted notification
  static Future<void> sendAdvisoryAcceptedNotification({
    required String raeUid,
    required String smeName,
    required String conversationId,
  }) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('uid', raeUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;
      
      await http.post(
        Uri.parse('${_supabase.supabaseUrl}/functions/v1/send-fcm-notification'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'title': 'Advisory Request Accepted! ✅',
          'body': '$smeName has accepted your request and is ready to help.',
          'data': {
            'type': 'advisory_accepted',
            'conversation_id': conversationId,
            'sme_name': smeName,
          },
        }),
      );
      
      print('✅ Advisory accepted notification sent');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  /// Send order dispatch notification
  static Future<void> sendOrderDispatchNotification({
    required String raeUid,
    required String orderId,
    required String productName,
  }) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('uid', raeUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;
      
      await http.post(
        Uri.parse('${_supabase.supabaseUrl}/functions/v1/send-fcm-notification'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'title': 'Order Dispatched! 📦',
          'body': 'Your order for $productName has been dispatched.',
          'data': {
            'type': 'order_dispatched',
            'order_id': orderId,
          },
        }),
      );
      
      print('✅ Order notification sent');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
