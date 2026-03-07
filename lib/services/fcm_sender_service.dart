import 'package:cloud_functions/cloud_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM Notification Service using Firebase Cloud Functions
/// 
/// IMPORTANT: This uses Firebase Cloud Functions to send notifications
/// because the legacy FCM HTTP API has been deprecated.
/// 
/// Setup Instructions:
/// 1. Install Firebase CLI: npm install -g firebase-tools
/// 2. Run: firebase init functions
/// 3. Create Cloud Functions (see FCM_V1_MIGRATION_GUIDE.md)
/// 4. Deploy: firebase deploy --only functions
/// 5. Enable "Firebase Cloud Messaging API" in Google Cloud Console
class FCMSenderService {
  static final _functions = FirebaseFunctions.instance;
  
  /// Send chat notification to user via Cloud Function
  static Future<void> sendChatNotification({
    required String receiverUid,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      // Get receiver's FCM token from database
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('uid', receiverUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for user: $receiverUid');
        return;
      }
      
      // Call Cloud Function to send notification
      final callable = _functions.httpsCallable('sendChatNotification');
      await callable.call({
        'fcmToken': fcmToken,
        'senderName': senderName,
        'message': message.length > 100 ? '${message.substring(0, 100)}...' : message,
        'conversationId': conversationId,
      });
      
      print('✅ Chat notification sent via Cloud Functions');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }
  
  /// Send order dispatch notification to RAE
  static Future<void> sendOrderDispatchNotification({
    required String raeUid,
    required String orderId, via Cloud Function
  static Future<void> sendOrderDispatchNotification({
    required String raeUid,
    required String orderId,
    required String productName,
  }) async {
    try {
      // Get RAE's FCM token
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token, name')
          .eq('uid', raeUid)
          .maybeSingle();
      
      final fcmToken = profile?['fcm_token'] as String?;
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ No FCM token found for RAE: $raeUid');
        return;
      }
      
      // Call Cloud Function
      final callable = _functions.httpsCallable('sendOrderNotification');
      await callable.call({
        'fcmToken': fcmToken,
        'orderId': orderId,
        'productName': productName,
      });
      
      print('✅ Order dispatch notification sent
  }
  
  /// Send advisory request notification to all district SMEs
  static Future<void> sendAdvisoryRequestNotification({
    required String raeUid,
    required String raeName,
    required String district, via Cloud Function
  static Future<void> sendAdvisoryRequestNotification({
    required String raeUid,
    required String raeName,
    required String district,
    required String topic,
    required String conversationId,
  }) async {
    try {
      // Get all SMEs in the same district
      final smes = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token')
          .eq('role', 'sme')
          .eq('district', district);
      
      if (smes.isEmpty) {
        print('⚠️ No SMEs found in district: $district');
        return;
      }
      
      // Extract FCM tokens
      final tokens = smes
          .map((s) => s['fcm_token'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();
      
      if (tokens.isEmpty) {
        print('⚠️ No SMEs with FCM tokens in district: $district');
        return;
      }
      
      // Call Cloud Function to send to all SMEs
      final callable = _functions.httpsCallable('sendAdvisoryNotification');
      final result = await callable.call({
        'smeTokens': tokens,
        'raeName': raeName,
        'topic': topic.length > 80 ? '${topic.substring(0, 80)}...' : topic,
        'conversationId': conversationId,
        'district': district,
      });
      
      print('✅ Advisory request sent to ${result.data['successCount']} SMEs
  
  /// Send notification when SME accepts advisory request
  static Future<void> sendAdvisoryAcceptedNotification({
    required String raeUid,
    required String smeName,
    required String conversationId, via Cloud Function
  static Future<void> sendAdvisoryAcceptedNotification({
    required String raeUid,
    required String smeName,
    required String conversationId,
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
        print('⚠️ No FCM token found for RAE: $raeUid');
        return;
      }
      
      // Call Cloud Function
      final callable = _functions.httpsCallable('sendAdvisoryAcceptedNotification');
      await callable.call({
        'fcmToken': fcmToken,
        'smeName': smeName,
        'conversationId': conversationId,
      });
      
      print('✅ Advisory accepted notification sent to RAE');
    } catch (e) {
      print('❌ Error sending advisory accepted