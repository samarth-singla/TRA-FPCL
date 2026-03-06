import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/admin_service.dart';

/// Order Approval Screen
///
/// Matches mockscreen:
///   – Blue header with back arrow "Order Approval"
///   – Segmented tab: Pending (N) | Approved (N)
///   – Pending cards: ORD id, RAE name+code, district+date, View Details, Approve/Reject
///   – Approved cards: ORD id, RAE info, total (green), approvedBy, date, Generate PO
class OrderApprovalScreen extends StatefulWidget {
  const OrderApprovalScreen({super.key});

  @override
  State<OrderApprovalScreen> createState() => _OrderApprovalScreenState();
}

class _OrderApprovalScreenState extends State<OrderApprovalScreen> {
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF16A34A);

  final _service = AdminService();
  final _adminUser = firebase_auth.FirebaseAuth.instance.currentUser;

  int _selectedTab = 0; // 0=Pending, 1=Approved

  List<OrderSummary> _pending = [];
  List<OrderSummary> _approved = [];
  bool _loadingPending = true;
  bool _loadingApproved = true;

  String get _adminName =>
      _adminUser?.displayName ?? _adminUser?.phoneNumber ?? 'Admin User';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadPending();
    _loadApproved();
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    final orders = await _service.getAllOrders(status: 'pending');
    if (mounted) setState(() { _pending = orders; _loadingPending = false; });
  }

  Future<void> _loadApproved() async {
    setState(() => _loadingApproved = true);
    final orders = await _service.getAllOrders(status: 'confirmed');
    if (mounted) setState(() { _approved = orders; _loadingApproved = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildPendingList()
                  : _buildApprovedList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        onPressed: _loadAll,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _blue,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Approval',
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

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _tab(0, 'Pending', _pending.length, _loadingPending),
            _tab(1, 'Approved', _approved.length, _loadingApproved),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, String label, int count, bool loading) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              loading ? label : '$label ($count)',
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF111827)
                    : const Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pending List ──────────────────────────────────────────────────────────

  Widget _buildPendingList() {
    if (_loadingPending) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pending.isEmpty) {
      return _emptyState('No pending orders', Icons.check_circle_outline);
    }
    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildPendingCard(_pending[index]),
      ),
    );
  }

  Widget _buildPendingCard(OrderSummary order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          // ── Order header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${order.raeName} (${order.raeCode})',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                      ),
                      Text(
                        '${order.district} • ${_fmtDate(order.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                _pendingBadge(),
              ],
            ),
          ),
          // View Details link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => _showOrderDetails(order),
              child: const Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined,
                      size: 16, color: Color(0xFF6B7280)),
                  SizedBox(width: 6),
                  Text(
                    'View Details',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // ── Buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(order),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(order),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Approved List ─────────────────────────────────────────────────────────

  Widget _buildApprovedList() {
    if (_loadingApproved) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_approved.isEmpty) {
      return _emptyState('No approved orders yet', Icons.description_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadApproved,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _approved.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildApprovedCard(_approved[index]),
      ),
    );
  }

  Widget _buildApprovedCard(OrderSummary order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.displayId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        order.raeName,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                      ),
                      Text(
                        order.district,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                _approvedBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      const TextSpan(
                          text: 'Total: ',
                          style: TextStyle(color: Color(0xFF374151))),
                      TextSpan(
                        text: '₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Approved by: ${order.approvedBy ?? 'Admin User'}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151)),
                ),
                Text(
                  'Date: ${_fmtDate(order.approvedAt ?? order.createdAt)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Generating PO for ${order.displayId}...')),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Generate PO'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _handleApprove(OrderSummary order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Order'),
        content: Text(
            'Approve ${order.displayId} from ${order.raeName}?\n\nAmount: ₹${order.totalAmount.toStringAsFixed(0)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.approveOrder(order.id, _adminName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${order.displayId} approved'),
            backgroundColor: _green,
          ),
        );
        _loadAll();
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

  void _handleReject(OrderSummary order) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${order.displayId} from ${order.raeName}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.rejectOrder(order.id, reasonCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${order.displayId} rejected')),
        );
        _loadPending();
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

  void _showOrderDetails(OrderSummary order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(order.displayId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('RAE:', order.raeName),
            _detailRow('Code:', order.raeCode),
            _detailRow('District:', order.district),
            _detailRow('Date:', _fmtDate(order.createdAt)),
            _detailRow('Amount:', '₹${order.totalAmount.toStringAsFixed(0)}'),
            _detailRow('Items:', '${order.itemCount}'),
            _detailRow('Status:', order.status.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _pendingBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
              color: Color(0xFFF97316),
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _approvedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Text(
          'Approved',
          style: TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            children: [
              TextSpan(
                  text: '$label ',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ],
          ),
        ),
      );

  Widget _emptyState(String message, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
