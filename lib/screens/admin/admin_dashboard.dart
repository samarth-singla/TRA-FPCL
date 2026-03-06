import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'order_approval_screen.dart';

/// FPCL Admin Dashboard — Web Portal
///
/// Matches mockscreen:
///   – Solid blue (#2563EB) header "FPCL Admin Dashboard"
///   – 2×2 stat cards (Pending Orders, Approved Today, Active RAEs, Total Orders)
///   – Quick Actions 2×2 grid
///   – Pending Approvals with "View All" → OrderApprovalScreen
///   – District Performance table
///   – Green FAB (menu)
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);

  final _service = AdminService();
  final _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

  String get _uid => _firebaseUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                    const SizedBox(height: 20),
                    _buildPendingApprovals(context),
                    const SizedBox(height: 20),
                    _buildDistrictPerformance(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _service.getAdminProfile(_uid),
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          color: _blue,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FPCL Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Order Management & Oversight',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Stat Cards ───────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    return FutureBuilder<AdminStats>(
      future: _service.getStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const AdminStats();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            _statCard(
              iconBg: const Color(0xFFF97316),
              icon: Icons.schedule,
              value: loading ? '–' : '${stats.pendingOrders}',
              label: 'Pending Orders',
            ),
            _statCard(
              iconBg: const Color(0xFF22C55E),
              icon: Icons.check_circle_outline,
              value: loading ? '–' : '${stats.approvedToday}',
              label: 'Approved Today',
            ),
            _statCard(
              iconBg: const Color(0xFF3B82F6),
              icon: Icons.people_outline,
              value: loading ? '–' : '${stats.activeRaes}',
              label: 'Active RAEs',
            ),
            _statCard(
              iconBg: const Color(0xFFA855F7),
              icon: Icons.shopping_bag_outlined,
              value: loading
                  ? '–'
                  : _fmtNumber(stats.totalOrders),
              label: 'Total Orders',
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required Color iconBg,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          // 2×2 grid of action tiles
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  icon: Icons.check_circle_outline,
                  label: 'Approve Orders',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderApprovalScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionTile(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  onTap: () => _snack(context, 'Reports – Coming Soon'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionTile(
                  icon: Icons.people_outline,
                  label: 'RAE Management',
                  onTap: () => _snack(context, 'RAE Management – Coming Soon'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Suppliers',
                  onTap: () => _snack(context, 'Suppliers – Coming Soon'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF374151)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pending Approvals ────────────────────────────────────────────────────

  Widget _buildPendingApprovals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OrderApprovalScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<OrderSummary>>(
          future: _service.getPendingOrders(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ));
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text('No pending orders',
                      style: TextStyle(color: Color(0xFF6B7280))),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: orders.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final order = entry.value;
                  return _pendingApprovalRow(
                    context,
                    order,
                    isLast: idx == orders.length - 1,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _pendingApprovalRow(
      BuildContext context, OrderSummary order,
      {required bool isLast}) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFFFFBF5),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          order.raeName,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF374151)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        '${order.itemCount} items',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleApproveDashboard(context, order),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Approve',
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _handleRejectDashboard(context, order),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        side:
                            const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE5E7EB)),
      ],
    );
  }

  void _handleApproveDashboard(
      BuildContext context, OrderSummary order) async {
    try {
      final adminName = _firebaseUser?.displayName ??
          _firebaseUser?.phoneNumber ??
          'Admin User';
      await _service.approveOrder(order.id, adminName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${order.displayId} approved'),
            backgroundColor: _green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleRejectDashboard(
      BuildContext context, OrderSummary order) async {
    try {
      await _service.rejectOrder(order.id, '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${order.displayId} rejected')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── District Performance ──────────────────────────────────────────────────

  Widget _buildDistrictPerformance() {
    return FutureBuilder<List<DistrictStat>>(
      future: _service.getDistrictPerformance(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, size: 18, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text(
                    'District Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (stats.isEmpty)
                const Text('No data available',
                    style: TextStyle(color: Color(0xFF6B7280)))
              else
                ...stats.map((s) => _districtRow(s)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _districtRow(DistrictStat stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.district,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
          Text(
            '${stat.orderCount} orders',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      onPressed: () => _showFabMenu(context),
      child: const Icon(Icons.menu, size: 26),
    );
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.check_circle_outline, color: _green),
              title: const Text('Approve Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OrderApprovalScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                _snack(context, 'Reports – Coming Soon');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('RAE Management'),
              onTap: () {
                Navigator.pop(context);
                _snack(context, 'RAE Management – Coming Soon');
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtNumber(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final thousands = s.substring(0, s.length - 3);
      final rest = s.substring(s.length - 3);
      return '$thousands,$rest';
    }
    return '$n';
  }
}
