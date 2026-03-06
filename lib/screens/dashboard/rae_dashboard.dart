import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../catalog/product_catalog_screen.dart';
import '../catalog/shopping_cart_screen.dart';
import '../rae/track_orders_screen.dart';
import '../rae/earnings_screen.dart';
import '../../services/auth_service.dart';

class RAEDashboard extends StatefulWidget {
  const RAEDashboard({super.key});

  @override
  State<RAEDashboard> createState() => _RAEDashboardState();
}

class _RAEDashboardState extends State<RAEDashboard> {
  static const _green = Color(0xFF2E9B33);

  final _supabase = Supabase.instance.client;
  final _fbUser = firebase_auth.FirebaseAuth.instance.currentUser;

  String _raeName = 'RAE User';
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _fbUser?.uid;
    if (uid == null) return;
    try {
      final row = await _supabase
          .from('profiles')
          .select('name')
          .eq('uid', uid)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() => _raeName = row['name']?.toString() ?? 'RAE User');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildActionsGrid(context),
                        const SizedBox(height: 20),
                        _buildRecentAlerts(),
                        const SizedBox(height: 20),
                        _buildQuickActionsRow(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_fabOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _fabOpen = false),
                  child: Container(color: Colors.black26),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final uid = _fbUser?.uid ?? '';
    return Container(
      color: _green,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showDrawer(context),
                  child: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RAE Dashboard',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 26),
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text('Notifications – coming soon'))),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline,
                      color: Colors.white, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Welcome, $_raeName',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('orders').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final all = snapshot.data ?? [];
              final mine = all.where((o) => o['rae_uid'] == uid).toList();
              final active = mine
                  .where((o) =>
                      o['status'] == 'pending' ||
                      o['status'] == 'confirmed' ||
                      o['status'] == 'dispatched')
                  .length;
              final totalAmt = mine.fold<double>(
                0,
                (s, o) =>
                    s +
                    ((o['total_amount'] ?? o['total'] ?? 0) as num).toDouble(),
              );
              final total = mine.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _headerStat('$active', 'Active Orders'),
                    const SizedBox(width: 8),
                    _headerStat('₹${_fmt(totalAmt)}', 'This Month'),
                    const SizedBox(width: 8),
                    _headerStat('$total', 'Total Orders'),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Action grid ────────────────────────────────────────────────────────

  Widget _buildActionsGrid(BuildContext context) {
    final uid = _fbUser?.uid ?? '';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('orders').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final mine = all.where((o) => o['rae_uid'] == uid).toList();
        final activeCount = mine
            .where((o) =>
                o['status'] == 'pending' ||
                o['status'] == 'confirmed' ||
                o['status'] == 'dispatched')
            .length;

        final actions = [
          {
            'title': 'Order Inputs',
            'subtitle': 'Browse & order products',
            'icon': Icons.shopping_bag_outlined,
            'color': const Color(0xFF1565C0),
            'badge': null as String?,
          },
          {
            'title': 'Track Orders',
            'subtitle': 'View order status',
            'icon': Icons.inventory_2_outlined,
            'color': _green,
            'badge': activeCount > 0 ? '$activeCount' : null as String?,
          },
          {
            'title': 'Advisory',
            'subtitle': 'Chat with SME',
            'icon': Icons.chat_bubble_outline,
            'color': const Color(0xFF7B1FA2),
            'badge': null as String?,
          },
          {
            'title': 'Earnings',
            'subtitle': 'View commissions',
            'icon': Icons.trending_up,
            'color': const Color(0xFFF57C00),
            'badge': null as String?,
          },
        ];

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: actions.map((a) {
            return _actionCard(
              context,
              title: a['title'] as String,
              subtitle: a['subtitle'] as String,
              icon: a['icon'] as IconData,
              color: a['color'] as Color,
              badge: a['badge'] as String?,
              onTap: () {
                final t = a['title'] as String;
                if (t == 'Order Inputs') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProductCatalogScreen()));
                } else if (t == 'Track Orders') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TrackOrdersScreen()));
                } else if (t == 'Earnings') {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EarningsScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$t – coming soon')));
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  // ── Recent Alerts ─────────────────────────────────────────────────────

  Widget _buildRecentAlerts() {
    final uid = _fbUser?.uid ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Alerts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 18, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {},
                  child: const Text('View All',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF2E9B33))),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream:
              _supabase.from('notifications').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final mine = all
                .where((n) => n['user_uid'] == uid)
                .toList()
              ..sort((a, b) {
                final da =
                    DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
                final db =
                    DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
                return db.compareTo(da);
              });
            final items = mine.isEmpty
                ? [
                    {'message': 'Order #1234 has been approved'},
                    {'message': 'New advisory message from District SME'},
                    {'message': 'Payment received for Order #1230'},
                  ]
                : mine.take(3).toList();
            return Column(
              children: items
                  .map((n) => _alertRow(n['message']?.toString() ??
                      n['title']?.toString() ??
                      'Notification'))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _alertRow(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions row ─────────────────────────────────────────────────

  Widget _buildQuickActionsRow(BuildContext context) {
    return Container(
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
          const Text('Quick Actions',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('New Order'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductCatalogScreen())),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('View Cart'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShoppingCartScreen())),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_fabOpen) ...[
          _fabOption(context, Icons.add_shopping_cart, 'New Order', () {
            setState(() => _fabOpen = false);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProductCatalogScreen()));
          }),
          const SizedBox(height: 8),
          _fabOption(context, Icons.inventory_2_outlined, 'Track Orders', () {
            setState(() => _fabOpen = false);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrackOrdersScreen()));
          }),
          const SizedBox(height: 8),
          _fabOption(context, Icons.trending_up, 'Earnings', () {
            setState(() => _fabOpen = false);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()));
          }),
          const SizedBox(height: 8),
          _fabOption(context, Icons.logout, 'Sign Out', () async {
            setState(() => _fabOpen = false);
            await AuthService().signOut();
          }),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          backgroundColor: _green,
          child:
              Icon(_fabOpen ? Icons.close : Icons.menu, color: Colors.white),
        ),
      ],
    );
  }

  Widget _fabOption(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _green),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(_raeName),
              subtitle: const Text('Rural Agripreneur Executive'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
