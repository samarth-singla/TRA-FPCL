import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a single conversation entry
class ConversationItem {
  final String id;
  final String raeUid;
  final String? smeUid; // Nullable for pending requests
  final String raeName;
  final String raeCode;
  final String raeDistrict;
  final String status; // 'pending' | 'active' | 'resolved'
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isResolved;

  ConversationItem({
    required this.id,
    required this.raeUid,
    this.smeUid,
    required this.raeName,
    required this.raeCode,
    required this.raeDistrict,
    required this.status,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isResolved,
  });

  factory ConversationItem.fromMap(Map<String, dynamic> map) {
    return ConversationItem(
      id: map['id']?.toString() ?? '',
      raeUid: map['rae_uid']?.toString() ?? '',
      smeUid: map['sme_uid']?.toString(),
      raeName: map['rae_name']?.toString() ?? '',
      raeCode: map['rae_code']?.toString() ?? '',
      raeDistrict: map['rae_district']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      lastMessage: map['last_message']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(map['last_message_at']?.toString() ?? '') ?? DateTime.now(),
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      isResolved: map['is_resolved'] as bool? ?? false,
    );
  }

  // Helper method to check if conversation is pending
  bool get isPending => status == 'pending';
  
  // Helper method to check if conversation is active
  bool get isActive => status == 'active';
}

/// Model for an issue / complaint
class IssueItem {
  final String id;
  final String raeUid;
  final String smeUid;
  final String raeName;
  final String title;
  final String description;
  final String status; // 'open' | 'resolved'
  final String priority; // 'high' | 'medium' | 'low'
  final DateTime createdAt;

  IssueItem({
    required this.id,
    required this.raeUid,
    required this.smeUid,
    required this.raeName,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory IssueItem.fromMap(Map<String, dynamic> map) {
    return IssueItem(
      id: map['id']?.toString() ?? '',
      raeUid: map['rae_uid']?.toString() ?? '',
      smeUid: map['sme_uid']?.toString() ?? '',
      raeName: map['rae_name']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
      priority: map['priority']?.toString() ?? 'medium',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Model for dashboard stat cards
class SmeDashboardStats {
  final int activeRaes;
  final int openChats;
  final int resolvedIssues;
  final int districtOrders;

  const SmeDashboardStats({
    this.activeRaes = 0,
    this.openChats = 0,
    this.resolvedIssues = 0,
    this.districtOrders = 0,
  });
}

/// Model for activity log (honorarium calculation)
class SmeActivityLog {
  final int chatsResolved;
  final int issuesHandled;
  final int raesMentored;

  const SmeActivityLog({
    this.chatsResolved = 0,
    this.issuesHandled = 0,
    this.raesMentored = 0,
  });
}

/// Model for district performance overview
class SmeDistrictPerformance {
  final int totalOrdersThisMonth;
  final int activeRaes;
  final int totalRaes;
  final int villagesCovered;
  final int farmersServed;

  const SmeDistrictPerformance({
    this.totalOrdersThisMonth = 0,
    this.activeRaes = 0,
    this.totalRaes = 50,
    this.villagesCovered = 0,
    this.farmersServed = 0,
  });
}

/// Service for all SME (District Advisor) dashboard data
class SmeService {
  static final SmeService _instance = SmeService._internal();
  factory SmeService() => _instance;
  SmeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // -----------------------------------------------------------------------
  // Stat Cards
  // -----------------------------------------------------------------------

  /// Fetch all 4 stat card numbers for the dashboard header grid.
  Future<SmeDashboardStats> getDashboardStats(String smeUid) async {
    try {
      // Fetch conversations, issues, and orders in parallel
      final results = await Future.wait([
        _supabase
            .from('conversations')
            .select('id')
            .eq('sme_uid', smeUid),
        _supabase
            .from('conversations')
            .select('id')
            .eq('sme_uid', smeUid)
            .eq('is_resolved', false),
        _supabase
            .from('issues')
            .select('id')
            .eq('sme_uid', smeUid)
            .eq('status', 'resolved'),
        _supabase
            .from('orders')
            .select('id')
            .eq('sme_uid', smeUid),
      ]);

      // Count unique RAE uids from conversations as "active RAEs"
      final allConvos = results[0] as List;
      final openChats = (results[1] as List).length;
      final resolvedIssues = (results[2] as List).length;
      final districtOrders = (results[3] as List).length;

      // Unique RAEs who have ever messaged this SME
      final raeUids = allConvos.map((c) => c['id']).toSet();
      final activeRaes = raeUids.length;

      return SmeDashboardStats(
        activeRaes: activeRaes,
        openChats: openChats,
        resolvedIssues: resolvedIssues,
        districtOrders: districtOrders,
      );
    } catch (e) {
      print('⚠️ SmeService.getDashboardStats error: $e');
      return const SmeDashboardStats();
    }
  }

  // -----------------------------------------------------------------------
  // Conversations Stream (realtime)
  // -----------------------------------------------------------------------

  /// Stream of conversations for this SME, newest first.
  /// Only returns active conversations (not pending requests).
  Stream<List<ConversationItem>> conversationsStream(String smeUid) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filtered = rows.where((r) {
            return r['sme_uid'] == smeUid && r['status'] == 'active';
          }).toList();
          filtered.sort((a, b) {
            final dateA = DateTime.tryParse(a['last_message_at'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['last_message_at'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          return filtered.map(ConversationItem.fromMap).toList();
        });
  }

  /// Count of conversations with unread messages
  int countUnread(List<ConversationItem> conversations) {
    return conversations.where((c) => c.unreadCount > 0).length;
  }

  /// Stream of pending advisory requests for this SME's district
  Stream<List<ConversationItem>> pendingRequestsStream(String smeDistrict) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filtered = rows.where((r) {
            return r['status'] == 'pending' && r['rae_district'] == smeDistrict;
          }).toList();
          
          // Sort by creation time, newest first
          filtered.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          
          return filtered.map(ConversationItem.fromMap).toList();
        });
  }

  /// Accept a pending advisory request (assign SME and activate conversation)
  Future<void> acceptAdvisoryRequest({
    required String conversationId,
    required String smeUid,
  }) async {
    // Update conversation with SME assignment and status change
    await _supabase
        .from('conversations')
        .update({
          'sme_uid': smeUid,
          'status': 'active',
        })
        .eq('id', conversationId)
        .eq('status', 'pending'); // Only update if still pending (race condition protection)
  }

  // -----------------------------------------------------------------------
  // Issues Stream (realtime)
  // -----------------------------------------------------------------------

  /// Stream of recent issues for this SME, newest first (capped at 5).
  Stream<List<IssueItem>> issuesStream(String smeUid) {
    return _supabase
        .from('issues')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filtered = rows.where((r) => r['sme_uid'] == smeUid).toList();
          filtered.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          return filtered.take(5).map(IssueItem.fromMap).toList();
        });
  }

  // -----------------------------------------------------------------------
  // District Performance
  // -----------------------------------------------------------------------

  /// Fetch district performance overview. Falls back to sme_metrics table first,
  /// then computes from raw tables if no metrics row exists.
  Future<SmeDistrictPerformance> getDistrictPerformance(String smeUid) async {
    try {
      // Try sme_metrics table first (fast path)
      final metricsRow = await _supabase
          .from('sme_metrics')
          .select()
          .eq('sme_uid', smeUid)
          .maybeSingle();

      if (metricsRow != null) {
        // Count orders this month
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
        final ordersThisMonth = await _supabase
            .from('orders')
            .select('id')
            .eq('sme_uid', smeUid)
            .gte('created_at', monthStart);

        return SmeDistrictPerformance(
          totalOrdersThisMonth: (ordersThisMonth as List).length,
          activeRaes: (metricsRow['active_raes'] as num?)?.toInt() ?? 0,
          totalRaes: (metricsRow['total_raes'] as num?)?.toInt() ?? 50,
          villagesCovered: (metricsRow['villages_covered'] as num?)?.toInt() ?? 0,
          farmersServed: (metricsRow['farmers_served'] as num?)?.toInt() ?? 0,
        );
      }

      // Fallback: compute from orders
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

      final ordersThisMonth = await _supabase
          .from('orders')
          .select('id, rae_uid')
          .eq('sme_uid', smeUid)
          .gte('created_at', monthStart);

      final activeRaeUids = (ordersThisMonth as List)
          .map((o) => o['rae_uid']?.toString() ?? '')
          .toSet()
          .where((uid) => uid.isNotEmpty)
          .length;

      return SmeDistrictPerformance(
        totalOrdersThisMonth: ordersThisMonth.length,
        activeRaes: activeRaeUids,
        totalRaes: 50,
        villagesCovered: 0,
        farmersServed: 0,
      );
    } catch (e) {
      print('⚠️ SmeService.getDistrictPerformance error: $e');
      return const SmeDistrictPerformance();
    }
  }

  // -----------------------------------------------------------------------
  // Activity Log (honorarium)
  // -----------------------------------------------------------------------

  /// Fetch activity log data for honorarium calculation.
  Future<SmeActivityLog> getActivityLog(String smeUid) async {
    try {
      final results = await Future.wait([
        // Chats resolved
        _supabase
            .from('conversations')
            .select('id')
            .eq('sme_uid', smeUid)
            .eq('is_resolved', true),
        // Issues handled (resolved)
        _supabase
            .from('issues')
            .select('id')
            .eq('sme_uid', smeUid)
            .eq('status', 'resolved'),
        // RAEs mentored (unique RAEs this SME has talked to)
        _supabase
            .from('conversations')
            .select('rae_uid')
            .eq('sme_uid', smeUid),
      ]);

      final chatsResolved = (results[0] as List).length;
      final issuesHandled = (results[1] as List).length;
      final allConvos = results[2] as List;
      final raesMentored = allConvos
          .map((c) => c['rae_uid']?.toString() ?? '')
          .toSet()
          .where((uid) => uid.isNotEmpty)
          .length;

      return SmeActivityLog(
        chatsResolved: chatsResolved,
        issuesHandled: issuesHandled,
        raesMentored: raesMentored,
      );
    } catch (e) {
      print('⚠️ SmeService.getActivityLog error: $e');
      return const SmeActivityLog();
    }
  }

  // -----------------------------------------------------------------------
  // Profile
  // -----------------------------------------------------------------------

  /// Fetch the SME's name and district from profiles table.
  Future<Map<String, String>> getSmeProfile(String uid) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('name, district')
          .eq('uid', uid)
          .maybeSingle();

      return {
        'name': row?['name']?.toString() ?? 'District Advisor',
        'district': row?['district']?.toString() ?? 'Hyderabad',
      };
    } on SocketException {
      return {'name': 'District Advisor', 'district': 'Hyderabad'};
    } catch (e) {
      print('⚠️ SmeService.getSmeProfile error: $e');
      return {'name': 'District Advisor', 'district': 'Hyderabad'};
    }
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  /// Mark an issue as resolved.
  Future<void> resolveIssue(String issueId) async {
    try {
      await _supabase.from('issues').update({
        'status': 'resolved',
        'updated_at': DateTime.now().toIso8601String(),
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', issueId);
    } catch (e) {
      throw Exception('Failed to resolve issue: $e');
    }
  }

  /// Mark a conversation as resolved and clear unread count.
  Future<void> markConversationRead(String conversationId) async {
    try {
      await _supabase.from('conversations').update({
        'unread_count': 0,
        'is_resolved': true,
      }).eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }
}
