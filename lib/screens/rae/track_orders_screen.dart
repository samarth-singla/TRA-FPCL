import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'order_detail_screen.dart';

class TrackOrdersScreen extends StatefulWidget {
  const TrackOrdersScreen({super.key});

  @override
  State<TrackOrdersScreen> createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2E9B33);

  late final TabController _tabController;
  final _supabase = Supabase.instance.client;
  final _fbUser = firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(active: true),
                  _buildOrderList(active: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final uid = _fbUser?.uid ?? '';
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Track Orders',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('orders').stream(primaryKey: ['id']),
            builder: (ctx, snap) {
              final all = snap.data ?? [];
              final mine = all.where((o) => o['rae_uid'] == uid).toList();
              final active = mine
                  .where((o) =>
                      o['status'] == 'pending' ||
                      o['status'] == 'confirmed' ||
                      o['status'] == 'dispatched' ||
                      o['status'] == 'shipped')
                  .length;
              return Text(
                '$active active',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final uid = _fbUser?.uid ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('orders').stream(primaryKey: ['id']),
      builder: (ctx, snap) {
        final all = snap.data ?? [];
        final mine = all.where((o) => o['rae_uid'] == uid).toList();
        final active = mine
            .where((o) =>
                o['status'] == 'pending' ||
                o['status'] == 'confirmed' ||
                o['status'] == 'dispatched' ||
                o['status'] == 'shipped')
            .length;
        final completed =
            mine.where((o) => o['status'] == 'delivered').length;

        return Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _green,
            unselectedLabelColor: const Color(0xFF9E9E9E),
            indicatorColor: _green,
            tabs: [
              Tab(text: 'Active ($active)'),
              Tab(text: 'Completed ($completed)'),
            ],
          ),
        );
      },
    );
  }

  // ── Order list ────────────────────────────────────────────────────────

  Widget _buildOrderList({required bool active}) {
    final uid = _fbUser?.uid ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('orders').stream(primaryKey: ['id']),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snap.data!;
        final mine = all.where((o) => o['rae_uid'] == uid).toList()
          ..sort((a, b) {
            final da =
                DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
            final db =
                DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
            return db.compareTo(da);
          });

        final filtered = active
            ? mine
                .where((o) =>
                    o['status'] == 'pending' ||
                    o['status'] == 'confirmed' ||
                    o['status'] == 'dispatched' ||
                    o['status'] == 'shipped')
                .toList()
            : mine.where((o) => o['status'] == 'delivered').toList();

        // Fall back to demo data if empty
        if (filtered.isEmpty) {
          final demoOrders = active
              ? [
                  {
                    'id': 'ORD1234',
                    'status': 'dispatched',
                    'created_at': '2024-06-01',
                    'total_amount': 4580.0,
                    'items': 3,
                    'expected_delivery': '2024-06-10',
                    'progress': 0.75,
                  },
                  {
                    'id': 'ORD1233',
                    'status': 'confirmed',
                    'created_at': '2024-05-28',
                    'total_amount': 2200.0,
                    'items': 2,
                    'expected_delivery': '2024-06-08',
                    'progress': 0.50,
                  },
                ]
              : [
                  {
                    'id': 'ORD1231',
                    'status': 'delivered',
                    'created_at': '2024-05-10',
                    'total_amount': 9320.0,
                    'items': 5,
                    'expected_delivery': '2024-05-15',
                    'progress': 1.0,
                  },
                ];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: demoOrders.length,
            itemBuilder: (ctx, i) => _orderCard(demoOrders[i], demo: true),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _orderCard(filtered[i]),
        );
      },
    );
  }

  // ── Order card ────────────────────────────────────────────────────────

  Widget _orderCard(Map<String, dynamic> order, {bool demo = false}) {
    final status = order['status']?.toString() ?? 'pending';
    final orderId = demo
        ? order['id'].toString()
        : '#${order['id']?.toString().substring(0, 8).toUpperCase() ?? '--------'}';
    final createdAt = order['created_at'] != null
        ? _formatDate(order['created_at'].toString())
        : 'N/A';
    final total =
        ((order['total_amount'] ?? order['total'] ?? 0) as num).toDouble();
    final items = (order['items'] ?? order['item_count'] ?? '-').toString();
    final expectedDelivery =
        order['expected_delivery']?.toString() ?? 'TBD';
    final double progress = demo
        ? (order['progress'] as double? ?? 0.5)
        : _progressFromStatus(status);

    final statusBg = _statusBgColor(status);
    final statusLabel = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + order id + status badge
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.local_shipping, color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demo ? 'Order $orderId' : 'Order $orderId',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(createdAt,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusBg,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress
          Row(
            children: [
              const Text('Order Progress',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF212121)),
            ),
          ),
          const SizedBox(height: 14),

          // Items + total
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text('$items Items',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF666666))),
              const Spacer(),
              Text('₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 8),

          // Expected delivery
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text('Expected Delivery: $expectedDelivery',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF666666))),
            ],
          ),
          const SizedBox(height: 14),

          // View Details button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final rawId = order['id']?.toString() ?? '';
                final isDemo = demo || rawId.isEmpty || rawId.startsWith('ORD');
                final displayId = demo
                    ? orderId
                    : '#${rawId.substring(0, 8).toUpperCase()}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(
                      orderId: isDemo ? '' : rawId,
                      displayId: displayId,
                      isDemo: isDemo,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: _green),
              ),
              child: const Text('View Details',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Color _statusBgColor(String status) {
    switch (status) {
      case 'dispatched':
      case 'shipped':
        return const Color(0xFF1565C0);
      case 'confirmed':
        return const Color(0xFFF57C00);
      case 'pending':
        return const Color(0xFF9E9E9E);
      case 'delivered':
        return _green;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'dispatched':
      case 'shipped':
        return 'Dispatched';
      case 'confirmed':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  double _progressFromStatus(String status) {
    switch (status) {
      case 'pending':
        return 0.25;
      case 'confirmed':
        return 0.50;
      case 'dispatched':
      case 'shipped':
        return 0.75;
      case 'delivered':
        return 1.0;
      default:
        return 0.1;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
