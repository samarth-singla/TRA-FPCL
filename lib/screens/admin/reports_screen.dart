import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// Admin Reports Screen
///
/// Sections:
///   – Summary stat cards (Total Orders, Revenue, Delivered, Pending)
///   – Monthly Orders bar chart (last 6 months)
///   – Orders by District horizontal bar chart
///   – Order status breakdown
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFF97316);
  static const _purple = Color(0xFFA855F7);

  final _service = AdminService();
  late Future<ReportData> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _service.getReportData();
  }

  void _refresh() => setState(() => _reportFuture = _service.getReportData());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<ReportData>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? const ReportData();
                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(data),
                          const SizedBox(height: 20),
                          _buildMonthlyChart(data),
                          const SizedBox(height: 20),
                          _buildDistrictChart(data),
                          const SizedBox(height: 20),
                          _buildStatusBreakdown(data),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Last 6 months',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Summary Cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards(ReportData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _summaryCard(
          icon: Icons.shopping_bag_outlined,
          iconBg: _blue,
          label: 'Total Orders',
          value: _fmtNumber(data.totalOrders),
        ),
        _summaryCard(
          icon: Icons.currency_rupee,
          iconBg: _green,
          label: 'Total Revenue',
          value: _fmtRevenue(data.totalRevenue),
        ),
        _summaryCard(
          icon: Icons.check_circle_outline,
          iconBg: _green,
          label: 'Delivered',
          value: _fmtNumber(data.deliveredOrders),
        ),
        _summaryCard(
          icon: Icons.schedule,
          iconBg: _orange,
          label: 'Pending',
          value: _fmtNumber(data.pendingOrders),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Orders Chart ─────────────────────────────────────────────────

  Widget _buildMonthlyChart(ReportData data) {
    final stats = data.monthlyStats;
    if (stats.isEmpty) return const SizedBox.shrink();

    final maxCount = stats.map((s) => s.count).fold(0, (a, b) => a > b ? a : b);
    final chartMax = maxCount == 0 ? 1 : maxCount;

    return _card(
      title: 'Monthly Orders',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((s) {
                final heightFrac = chartMax == 0 ? 0.0 : s.count / chartMax;
                final barHeight = (heightFrac * 130).clamp(4.0, 130.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (s.count > 0)
                          Text(
                            '${s.count}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.month.split(' ').first, // 'Jan', 'Feb', etc.
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── District Chart ────────────────────────────────────────────────────────

  Widget _buildDistrictChart(ReportData data) {
    final stats = data.districtStats.take(5).toList();
    if (stats.isEmpty) return const SizedBox.shrink();

    final maxCount =
        stats.map((s) => s.orderCount).fold(0, (a, b) => a > b ? a : b);

    return _card(
      title: 'Orders by District',
      icon: Icons.location_on_outlined,
      child: Column(
        children: stats.map((s) {
          final frac = maxCount == 0 ? 0.0 : s.orderCount / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.district,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    Text(
                      '${s.orderCount} orders',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_fmtRevenue(s.totalRevenue)} revenue',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Status Breakdown ──────────────────────────────────────────────────────

  Widget _buildStatusBreakdown(ReportData data) {
    final total = data.totalOrders == 0 ? 1 : data.totalOrders;
    final inProgress =
        data.totalOrders - data.deliveredOrders - data.pendingOrders;

    final statuses = [
      _StatusEntry('Delivered', data.deliveredOrders, _green),
      _StatusEntry('In Progress', inProgress.clamp(0, total), _blue),
      _StatusEntry('Pending', data.pendingOrders, _orange),
      _StatusEntry(
        'Cancelled',
        (total - data.deliveredOrders - inProgress.clamp(0, total) -
                data.pendingOrders)
            .clamp(0, total),
        Colors.red,
      ),
    ];

    return _card(
      title: 'Order Status Breakdown',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: statuses.map((s) {
          final pct = s.count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.label,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF374151)),
                          ),
                          const Spacer(),
                          Text(
                            '${s.count}  (${(pct * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(s.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Reusable card ────────────────────────────────────────────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF374151)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  String _fmtRevenue(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}k';
    return '₹${n.toStringAsFixed(0)}';
  }
}

class _StatusEntry {
  final String label;
  final int count;
  final Color color;
  const _StatusEntry(this.label, this.count, this.color);
}
