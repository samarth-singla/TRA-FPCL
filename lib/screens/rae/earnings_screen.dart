import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF2E9B33);
  static const _greenButton = Color(0xFF43A047);

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

  // ── Demo data ──────────────────────────────────────────────────────────

  static const _monthlyData = [
    {
      'month': 'June 2024',
      'total': 8420.0,
      'orders': 7,
      'commission': 5200.0,
      'incentives': 3220.0,
    },
    {
      'month': 'May 2024',
      'total': 11350.0,
      'orders': 10,
      'commission': 7100.0,
      'incentives': 4250.0,
    },
    {
      'month': 'April 2024',
      'total': 6780.0,
      'orders': 6,
      'commission': 4200.0,
      'incentives': 2580.0,
    },
    {
      'month': 'March 2024',
      'total': 9910.0,
      'orders': 9,
      'commission': 6300.0,
      'incentives': 3610.0,
    },
    {
      'month': 'February 2024',
      'total': 5400.0,
      'orders': 5,
      'commission': 3400.0,
      'incentives': 2000.0,
    },
    {
      'month': 'January 2024',
      'total': 7600.0,
      'orders': 7,
      'commission': 4800.0,
      'incentives': 2800.0,
    },
  ];

  static const _quarterlyData = [
    {
      'label': 'Q2 2024 (Apr–Jun)',
      'total': 26550.0,
      'orders': 23,
      'commission': 16500.0,
      'incentives': 10050.0,
    },
    {
      'label': 'Q1 2024 (Jan–Mar)',
      'total': 22910.0,
      'orders': 21,
      'commission': 14500.0,
      'incentives': 8410.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase.from('orders').stream(primaryKey: ['id']),
                builder: (ctx, snap) {
                  final uid = _fbUser?.uid ?? '';
                  final all = snap.data ?? [];
                  final mine =
                      all.where((o) => o['rae_uid'] == uid).toList();
                  final totalOrders = mine.length;
                  final totalEarnings = mine.fold<double>(
                    0,
                    (s, o) =>
                        s +
                        ((o['total_amount'] ?? o['total'] ?? 0) as num)
                            .toDouble() *
                            0.05,
                  );
                  final thisMonth = _monthlyData.first['total'] as double;
                  final avgCommission = totalOrders > 0
                      ? totalEarnings / totalOrders
                      : 1135.0;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTopCards(thisMonth, totalEarnings),
                          const SizedBox(height: 14),
                          _buildSmallCards(
                              totalOrders > 0 ? totalOrders : 128,
                              totalOrders > 0 ? avgCommission : 1135.0),
                          const SizedBox(height: 20),
                          _buildTabBar(),
                          const SizedBox(height: 12),
                          _buildBreakdownList(),
                          const SizedBox(height: 20),
                          _buildDownloadButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
              'Earnings & Incentives',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top stat cards ────────────────────────────────────────────────────

  Widget _buildTopCards(double thisMonth, double totalEarnings) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _greenButton,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('₹${_fmt(thisMonth)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Commission + Incentives',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('Total Earnings',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.trending_up, color: Colors.white70, size: 14),
                  ],
                ),
                const SizedBox(height: 8),
                Text('₹${_fmt(totalEarnings > 0 ? totalEarnings : 49460)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('All time earnings',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Small cards row ───────────────────────────────────────────────────

  Widget _buildSmallCards(int totalOrders, double avgCommission) {
    return Row(
      children: [
        Expanded(child: _smallCard('Total Orders', '$totalOrders')),
        const SizedBox(width: 12),
        Expanded(
            child: _smallCard(
                'Avg. Commission', '₹${avgCommission.toStringAsFixed(0)}',
                valueColor: _green)),
      ],
    );
  }

  Widget _smallCard(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF212121))),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
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
      child: TabBar(
        controller: _tabController,
        labelColor: _green,
        unselectedLabelColor: const Color(0xFF9E9E9E),
        indicatorColor: _green,
        indicator: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: _green, width: 2)),
        ),
        tabs: const [
          Tab(text: 'Monthly'),
          Tab(text: 'Quarterly'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  // ── Breakdown list ────────────────────────────────────────────────────

  Widget _buildBreakdownList() {
    final isMonthly = _tabController.index == 0;
    final data = isMonthly ? _monthlyData : _quarterlyData;

    return Column(
      children: data.map((item) {
        final label =
            (item['month'] ?? item['label'])?.toString() ?? '';
        final total = (item['total'] as double?) ?? 0;
        final orders = (item['orders'] as int?) ?? 0;
        final commission = (item['commission'] as double?) ?? 0;
        final incentives = (item['incentives'] as double?) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Theme(
            data:
                Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('$orders orders',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  Text('₹${_fmt(total)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _green)),
                ],
              ),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 10),
                _subRow('Commission', commission),
                const SizedBox(height: 6),
                _subRow('Incentives', incentives),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subRow(String label, double amount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E), shape: BoxShape.circle),
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF666666))),
        const Spacer(),
        Text('₹${_fmt(amount)}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Download button ───────────────────────────────────────────────────

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Download Income Statement',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Download feature – coming soon'))),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
