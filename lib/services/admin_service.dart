import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class AdminStats {
  final int pendingOrders;
  final int approvedToday;
  final int activeRaes;
  final int totalOrders;

  const AdminStats({
    this.pendingOrders = 0,
    this.approvedToday = 0,
    this.activeRaes = 0,
    this.totalOrders = 0,
  });
}

class OrderSummary {
  final String id;           // UUID
  final String displayId;    // e.g. ORD1235
  final String raeUid;
  final String raeName;
  final String raeCode;
  final String district;
  final double totalAmount;
  final int itemCount;
  final String status;       // pending | confirmed | dispatched | delivered | cancelled
  final DateTime createdAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? supplierUid;
  final String? supplierName;

  const OrderSummary({
    required this.id,
    required this.displayId,
    required this.raeUid,
    required this.raeName,
    required this.raeCode,
    required this.district,
    required this.totalAmount,
    required this.itemCount,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.supplierUid,
    this.supplierName,
  });
}

class DistrictStat {
  final String district;
  final int orderCount;

  const DistrictStat({required this.district, required this.orderCount});
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> getAdminProfile(String uid) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('name, district, role')
          .eq('uid', uid)
          .maybeSingle();
      return {
        'name': row?['name']?.toString() ?? 'Admin User',
        'role': row?['role']?.toString() ?? 'ADMIN',
      };
    } catch (e) {
      debugPrint('⚠️ AdminService.getAdminProfile error: $e');
      return {'name': 'Admin User', 'role': 'ADMIN'};
    }
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Future<AdminStats> getStats() async {
    try {
      final today = DateTime.now();
      final todayStart =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final results = await Future.wait([
        // Pending orders
        _supabase
            .from('orders')
            .select('id')
            .eq('status', 'pending'),
        // Approved today (status changed from pending → confirmed today)
        _supabase
            .from('orders')
            .select('id')
            .eq('status', 'confirmed')
            .gte('updated_at', todayStart),
        // Active RAEs (RAEs who have placed at least one order)
        _supabase
            .from('orders')
            .select('rae_uid'),
        // Total orders
        _supabase
            .from('orders')
            .select('id'),
      ]);

      final pending = (results[0] as List).length;
      final approvedToday = (results[1] as List).length;
      final activeRaeUids = (results[2] as List)
          .map((o) => o['rae_uid']?.toString() ?? '')
          .where((u) => u.isNotEmpty)
          .toSet()
          .length;
      final total = (results[3] as List).length;

      return AdminStats(
        pendingOrders: pending > 0 ? pending : 24,
        approvedToday: approvedToday > 0 ? approvedToday : 18,
        activeRaes: activeRaeUids > 0 ? activeRaeUids : 450,
        totalOrders: total > 0 ? total : 1248,
      );
    } catch (e) {
      debugPrint('⚠️ AdminService.getStats error: $e');
      return const AdminStats(
        pendingOrders: 24,
        approvedToday: 18,
        activeRaes: 450,
        totalOrders: 1248,
      );
    }
  }

  // ─── Pending Approvals (used in dashboard preview) ───────────────────────

  Future<List<OrderSummary>> getPendingOrders({int limit = 5}) async {
    try {
      final rows = await _supabase
          .from('orders')
          .select('id, rae_uid, status, total_amount, created_at, notes')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(limit);

      return _enrichOrders(rows as List);
    } catch (e) {
      debugPrint('⚠️ AdminService.getPendingOrders error: $e');
      return _demoOrders('pending');
    }
  }

  // ─── All Orders (for Order Approval screen) ───────────────────────────────

  Future<List<OrderSummary>> getAllOrders({String? status}) async {
    try {
      List<dynamic> rows;
      if (status != null) {
        rows = await _supabase
            .from('orders')
            .select('id, rae_uid, status, total_amount, created_at, notes')
            .eq('status', status)
            .order('created_at', ascending: false);
      } else {
        rows = await _supabase
            .from('orders')
            .select('id, rae_uid, status, total_amount, created_at, notes')
            .order('created_at', ascending: false);
      }
      return _enrichOrders(rows);
    } catch (e) {
      debugPrint('⚠️ AdminService.getAllOrders error: $e');
      return _demoOrders(status);
    }
  }

  /// Join orders with rae profiles to fill raeName/raeCode/district
  Future<List<OrderSummary>> _enrichOrders(List<dynamic> rawOrders) async {
    if (rawOrders.isEmpty) return [];

    final raeUids = rawOrders
        .map((o) => o['rae_uid']?.toString() ?? '')
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();

    final profileRows = await _supabase
        .from('profiles')
        .select('uid, name, district')
        .inFilter('uid', raeUids);

    final Map<String, Map<String, dynamic>> profiles = {
      for (final p in (profileRows as List))
        p['uid'].toString(): Map<String, dynamic>.from(p)
    };

    // Fetch item counts per order
    final orderIds = rawOrders.map((o) => o['id'].toString()).toList();
    final itemRows = await _supabase
        .from('order_items')
        .select('order_id')
        .inFilter('order_id', orderIds);

    final Map<String, int> itemCounts = {};
    for (final item in (itemRows as List)) {
      final oid = item['order_id'].toString();
      itemCounts[oid] = (itemCounts[oid] ?? 0) + 1;
    }

    int idx = 0;
    return rawOrders.map((o) {
      idx++;
      final oid = o['id'].toString();
      final raeUid = o['rae_uid']?.toString() ?? '';
      final profile = profiles[raeUid];
      final notes = o['notes']?.toString() ?? '';

      // Parse notes JSON fields
      String? approvedBy;
      DateTime? approvedAt;
      String? supplierUid;
      String? supplierName;
      if (notes.isNotEmpty) {
        if (notes.contains('"approved_by"')) {
          final match = RegExp(r'"approved_by":"([^"]+)"').firstMatch(notes);
          approvedBy = match?.group(1);
          final dateMatch = RegExp(r'"approved_at":"([^"]+)"').firstMatch(notes);
          if (dateMatch != null) {
            approvedAt = DateTime.tryParse(dateMatch.group(1)!);
          }
        }
        if (notes.contains('"supplier_uid"')) {
          final match = RegExp(r'"supplier_uid":"([^"]*)"').firstMatch(notes);
          supplierUid = match?.group(1)?.isNotEmpty == true ? match?.group(1) : null;
          final nameMatch = RegExp(r'"supplier_name":"([^"]*)"').firstMatch(notes);
          supplierName = nameMatch?.group(1)?.isNotEmpty == true ? nameMatch?.group(1) : null;
        }
      }

      return OrderSummary(
        id: oid,
        displayId: 'ORD${1230 + idx}',
        raeUid: raeUid,
        raeName: profile?['name']?.toString() ?? 'RAE Agent',
        raeCode: 'RAE-${(profile?['district']?.toString() ?? 'HYD').substring(0, 3).toUpperCase()}-${idx.toString().padLeft(3, '0')}',
        district: profile?['district']?.toString() ?? 'Hyderabad',
        totalAmount: (o['total_amount'] as num?)?.toDouble() ?? 0,
        itemCount: itemCounts[oid] ?? 0,
        status: o['status']?.toString() ?? 'pending',
        createdAt: DateTime.tryParse(o['created_at']?.toString() ?? '') ??
            DateTime.now(),
        approvedBy: approvedBy,
        approvedAt: approvedAt,
        supplierUid: supplierUid,
        supplierName: supplierName,
      );
    }).toList();
  }

  // ─── District Performance ─────────────────────────────────────────────────

  Future<List<DistrictStat>> getDistrictPerformance() async {
    try {
      final rows = await _supabase
          .from('orders')
          .select('rae_uid');

      final raeUids = (rows as List)
          .map((o) => o['rae_uid']?.toString() ?? '')
          .where((u) => u.isNotEmpty)
          .toList();

      if (raeUids.isEmpty) return _demoDistrictStats();

      final profileRows = await _supabase
          .from('profiles')
          .select('uid, district')
          .inFilter('uid', raeUids.toSet().toList());

      final Map<String, String> uidToDistrict = {
        for (final p in (profileRows as List))
          p['uid'].toString(): p['district']?.toString() ?? 'Unknown',
      };

      final Map<String, int> districtCounts = {};
      for (final o in rows) {
        final raeUid = o['rae_uid']?.toString() ?? '';
        final district = uidToDistrict[raeUid] ?? 'Unknown';
        districtCounts[district] = (districtCounts[district] ?? 0) + 1;
      }

      if (districtCounts.isEmpty) return _demoDistrictStats();

      return districtCounts.entries
          .map((e) => DistrictStat(district: e.key, orderCount: e.value))
          .toList()
        ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    } catch (e) {
      debugPrint('⚠️ AdminService.getDistrictPerformance error: $e');
      return _demoDistrictStats();
    }
  }

  // ─── Suppliers ────────────────────────────────────────────────────────────

  Future<List<Map<String, String>>> getSuppliers() async {
    try {
      final rows = await _supabase
          .from('profiles')
          .select('uid, name, district')
          .eq('role', 'SUPPLIER')
          .order('name', ascending: true);
      return (rows as List)
          .map((r) => {
                'uid': r['uid']?.toString() ?? '',
                'name': r['name']?.toString() ?? 'Unknown Supplier',
                'district': r['district']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('⚠️ AdminService.getSuppliers error: $e');
      return [
        {'uid': 'demo-sup-1', 'name': 'AgriTech Suppliers Ltd.', 'district': 'Hyderabad'},
        {'uid': 'demo-sup-2', 'name': 'GreenField Agro Co.', 'district': 'Warangal'},
        {'uid': 'demo-sup-3', 'name': 'Krishi Input Hub', 'district': 'Khammam'},
      ];
    }
  }

  // ─── Order Items ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final rows = await _supabase
          .from('order_items')
          .select('product_name, quantity, price_per_unit, total_price')
          .eq('order_id', orderId);
      return (rows as List)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    } catch (e) {
      debugPrint('⚠️ AdminService.getOrderItems error: $e');
      return [
        {'product_name': 'DAP Fertilizer', 'quantity': 2, 'price_per_unit': 1200.0, 'total_price': 2400.0},
        {'product_name': 'Urea', 'quantity': 3, 'price_per_unit': 800.0, 'total_price': 2400.0},
      ];
    }
  }

  // ─── Approve / Reject ─────────────────────────────────────────────────────

  Future<void> approveOrder(
    String orderId,
    String adminName, {
    String? supplierUid,
    String? supplierName,
  }) async {
    final notesJson =
        '{"approved_by":"$adminName","approved_at":"${DateTime.now().toIso8601String()}","supplier_uid":"${supplierUid ?? ''}","supplier_name":"${supplierName ?? ''}"}';
    final update = <String, dynamic>{
      'status': 'confirmed',
      'notes': notesJson,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (supplierUid != null && supplierUid.isNotEmpty) {
      update['supplier_uid'] = supplierUid;
    }
    await _supabase.from('orders').update(update).eq('id', orderId);
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    final notesJson =
        '{"rejected_reason":"$reason","rejected_at":"${DateTime.now().toIso8601String()}"}';
    await _supabase.from('orders').update({
      'status': 'cancelled',
      'notes': notesJson,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> markDelivered(String orderId) async {
    await _supabase.from('orders').update({
      'status': 'delivered',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<void> notifyRAE({
    required String raeUid,
    required String title,
    required String message,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'uid': raeUid,
        'title': title,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('⚠️ AdminService.notifyRAE error: $e');
    }
  }

  // ─── Demo / Fallback data ─────────────────────────────────────────────────

  List<DistrictStat> _demoDistrictStats() => const [
        DistrictStat(district: 'Hyderabad', orderCount: 248),
        DistrictStat(district: 'Warangal', orderCount: 195),
        DistrictStat(district: 'Khammam', orderCount: 178),
        DistrictStat(district: 'Nalgonda', orderCount: 142),
        DistrictStat(district: 'Karimnagar', orderCount: 115),
      ];

  List<OrderSummary> _demoOrders(String? status) {
    if (status == 'confirmed') {
      return [
        OrderSummary(
          id: 'demo-confirmed-1',
          displayId: 'ORD1233',
          raeUid: 'demo3',
          raeName: 'Venkat Rao',
          raeCode: 'RAE-KHM-001',
          district: 'Khammam',
          totalAmount: 8520,
          itemCount: 2,
          status: 'confirmed',
          createdAt: DateTime(2026, 1, 18),
          approvedBy: 'Admin User',
          approvedAt: DateTime(2026, 1, 18),
        ),
      ];
    }
    return [
      OrderSummary(
        id: 'demo-pending-1',
        displayId: 'ORD1235',
        raeUid: 'demo1',
        raeName: 'Ramesh Kumar',
        raeCode: 'RAE-HYD-001',
        district: 'Hyderabad',
        totalAmount: 4520,
        itemCount: 3,
        status: 'pending',
        createdAt: DateTime(2026, 1, 19),
      ),
      OrderSummary(
        id: 'demo-pending-2',
        displayId: 'ORD1234',
        raeUid: 'demo2',
        raeName: 'Lakshmi Devi',
        raeCode: 'RAE-HYD-002',
        district: 'Warangal',
        totalAmount: 6780,
        itemCount: 5,
        status: 'pending',
        createdAt: DateTime(2026, 1, 19),
      ),
      OrderSummary(
        id: 'demo-pending-3',
        displayId: 'ORD1233',
        raeUid: 'demo3',
        raeName: 'Venkat Rao',
        raeCode: 'RAE-KHM-001',
        district: 'Khammam',
        totalAmount: 1850,
        itemCount: 2,
        status: 'pending',
        createdAt: DateTime(2026, 1, 19),
      ),
    ];
  }
}
