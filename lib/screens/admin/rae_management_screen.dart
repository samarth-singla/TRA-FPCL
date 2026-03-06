import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

/// RAE Management Screen
///
/// Lists all RAEs with their order statistics.
/// Features:
///   – Search by name or district
///   – Stat cards: Total RAEs, Active RAEs (placed ≥1 order)
///   – RAE cards: name, district, orders (total/pending/delivered), revenue
///   – Expandable card shows order status breakdown
class RaeManagementScreen extends StatefulWidget {
  const RaeManagementScreen({super.key});

  @override
  State<RaeManagementScreen> createState() => _RaeManagementScreenState();
}

class _RaeManagementScreenState extends State<RaeManagementScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFF97316);

  final _service = AdminService();
  final _searchCtrl = TextEditingController();

  List<RaeInfo> _raes = [];
  List<RaeInfo> _filtered = [];
  bool _loading = true;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final raes = await _service.getRaes();
    if (mounted) {
      setState(() {
        _raes = raes;
        _applyFilter();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_raes)
          : _raes
              .where((r) =>
                  r.name.toLowerCase().contains(q) ||
                  r.district.toLowerCase().contains(q))
              .toList();
    });
  }

  int get _activeCount => _raes.where((r) => r.totalOrders > 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryRow(),
                                  const SizedBox(height: 14),
                                  _buildSearchBar(),
                                  const SizedBox(height: 14),
                                  Text(
                                    'RAE Agents (${_filtered.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                          if (_filtered.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No RAEs found',
                                      style: TextStyle(
                                          color: Colors.grey[500], fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) =>
                                      _buildRaeCard(_filtered[i]),
                                  childCount: _filtered.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        onPressed: _load,
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
                  'RAE Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Row ──────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
            icon: Icons.people_outline,
            iconBg: _blue,
            label: 'Total RAEs',
            value: '${_raes.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard(
            icon: Icons.person_outline,
            iconBg: _green,
            label: 'Active RAEs',
            value: '$_activeCount',
          ),
        ),
      ],
    );
  }

  Widget _miniCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            children: [
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
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by name or district…',
          hintStyle:
              const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: Color(0xFF6B7280), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── RAE Card ─────────────────────────────────────────────────────────────

  Widget _buildRaeCard(RaeInfo rae) {
    final isExpanded = _expanded.contains(rae.uid);
    final hasOrders = rae.totalOrders > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // ── Main row ──────────────────────────────────────────────────────
          InkWell(
            onTap: hasOrders
                ? () => setState(() {
                      if (isExpanded) {
                        _expanded.remove(rae.uid);
                      } else {
                        _expanded.add(rae.uid);
                      }
                    })
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Center(
                          child: Text(
                            rae.name.isNotEmpty
                                ? rae.name[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rae.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 12, color: Color(0xFF6B7280)),
                                const SizedBox(width: 2),
                                Text(
                                  rae.district,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasOrders
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasOrders
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Text(
                          hasOrders ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: hasOrders ? _green : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _statPill(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Total',
                        value: '${rae.totalOrders}',
                        color: _blue,
                      ),
                      const SizedBox(width: 8),
                      _statPill(
                        icon: Icons.check_circle_outline,
                        label: 'Done',
                        value: '${rae.deliveredOrders}',
                        color: _green,
                      ),
                      const SizedBox(width: 8),
                      _statPill(
                        icon: Icons.schedule,
                        label: 'Pending',
                        value: '${rae.pendingOrders}',
                        color: _orange,
                      ),
                      const Spacer(),
                      Text(
                        _fmtRevenue(rae.totalRevenue),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  if (hasOrders) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          isExpanded ? 'Hide details' : 'Show details',
                          style: const TextStyle(
                              fontSize: 12, color: _blue),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: _blue,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Expanded details ──────────────────────────────────────────────
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _breakdownRow(
                      'Delivered', rae.deliveredOrders, rae.totalOrders, _green),
                  const SizedBox(height: 6),
                  _breakdownRow(
                      'Pending',
                      rae.pendingOrders,
                      rae.totalOrders,
                      _orange),
                  const SizedBox(height: 6),
                  _breakdownRow(
                      'In Progress',
                      (rae.totalOrders -
                              rae.deliveredOrders -
                              rae.pendingOrders)
                          .clamp(0, rae.totalOrders),
                      rae.totalOrders,
                      _blue),
                  if (rae.lastOrderDate != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Last Order: ${_fmtDate(rae.lastOrderDate!)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                  if (rae.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          rae.phone,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, int count, int total, Color color) {
    final frac = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtRevenue(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(0)}k';
    return '₹${n.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
