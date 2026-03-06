import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/supplier_service.dart';
import '../../services/auth_service.dart';
import '../supplier/catalogue_management_screen.dart';
import '../profile/profile_screen.dart';

/// Supplier Portal Dashboard
///
/// Matches the mockscreen exactly:
///   – Blue-indigo gradient header with "Supplier Portal" branding
///   – 2×2 stat cards (Bulk POs, RAE Orders, In Transit, Pending Invoices)
///   – Quick Actions (Manage Catalogue, View Reports)
///   – Bulk Purchase Orders list (expandable cards per district)
///   – Performance Summary section
///   – Green FAB
class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  final _service = SupplierService();
  final _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

  // ── Colour palette ────────────────────────────────────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _indigoDeep = Color(0xFF3730A3);
  static const _greenFab = Color(0xFF16A34A);
  static const _greenAccent = Color(0xFF16A34A);
  static const _orangeBadge = Color(0xFFF97316);
  static const _blueBadge = Color(0xFF3B82F6);

  String get _uid => _firebaseUser?.uid ?? '';

  // Track which bulk PO cards are expanded
  final Set<String> _expandedPos = {};

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
                    _buildBulkOrdersSection(),
                    const SizedBox(height: 20),
                    _buildPerformanceSummary(),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _service.getSupplierProfile(_uid),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'] ?? 'AgriTech Co.';
        final supplierId = snapshot.data?['supplierId'] ?? 'SUP-001';

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_indigo, _indigoDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supplier Portal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$name - Supplier ID: $supplierId',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stat Cards
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    return FutureBuilder<SupplierStats>(
      future: _service.getStats(_uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const SupplierStats();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _statCard(
              icon: Icons.description_outlined,
              iconColor: Colors.white,
              iconBg: const Color(0xFF3B82F6),
              value: isLoading ? '–' : '${stats.bulkPos}',
              label: 'Bulk POs',
            ),
            _statCard(
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.white,
              iconBg: const Color(0xFF22C55E),
              value: isLoading ? '–' : '${stats.raeOrders}',
              label: 'RAE Orders',
            ),
            _statCard(
              icon: Icons.local_shipping_outlined,
              iconColor: Colors.white,
              iconBg: const Color(0xFFF97316),
              value: isLoading ? '–' : '${stats.inTransit}',
              label: 'In Transit',
            ),
            _statCard(
              icon: Icons.upload_outlined,
              iconColor: Colors.white,
              iconBg: const Color(0xFFA855F7),
              value: isLoading ? '–' : '${stats.pendingInvoices}',
              label: 'Pending Invoices',
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Actions
  // ─────────────────────────────────────────────────────────────────────────

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
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF374151)),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CatalogueManagementScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Manage Catalogue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reports – Coming Soon')),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('View Reports'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bulk Purchase Orders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBulkOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: Color(0xFF374151)),
            const SizedBox(width: 8),
            const Text(
              'Bulk Purchase Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _blueBadge,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Consolidated POs',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<BulkPurchaseOrder>>(
          future: _service.getBulkOrders(_uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final pos = snapshot.data ?? [];
            if (pos.isEmpty) {
              return _emptyCard('No purchase orders yet');
            }
            return Column(
              children: pos.map((po) => _buildBulkPoCard(po)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBulkPoCard(BulkPurchaseOrder po) {
    final isExpanded = _expandedPos.contains(po.bulkPoId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── PO Header ──────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedPos.remove(po.bulkPoId);
              } else {
                _expandedPos.add(po.bulkPoId);
              }
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          po.bulkPoId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      _statusBadge(po.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${po.district} • ${_fmtDate(po.date)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _infoChip('Total RAE Orders:', '${po.totalRaeOrders}', bold: true),
                            const Spacer(),
                            _infoChip('Total Amount:', '₹${_fmtAmount(po.totalAmount)}',
                                valueColor: _greenAccent, bold: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _infoChip('Delivery Date:', _fmtDate(po.deliveryDate)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded: Individual RAE Orders ───────────────────────
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Individual RAE Orders',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${po.raeOrders.length} Orders',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: po.raeOrders.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 12, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) =>
                    _buildRaeOrderRow(po.raeOrders[index]),
              ),
            ),
            const SizedBox(height: 12),
            // ── Action Buttons ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  if (po.status == 'pending_invoices')
                    _actionButton(
                      icon: Icons.description_outlined,
                      label:
                          'Generate Individual Invoices (${po.raeOrders.length} RAEs)',
                      color: _indigo,
                      onTap: () => _handleGenerateInvoices(po),
                    ),
                  if (po.status == 'ready_to_dispatch')
                    _actionButton(
                      icon: Icons.local_shipping_outlined,
                      label: 'Add Delivery Partner & Dispatch',
                      color: _greenAccent,
                      onTap: () => _showDispatchDialog(context, po),
                    ),
                  const SizedBox(height: 8),
                  _actionButton(
                    icon: Icons.description_outlined,
                    label: 'View Complete PO Details',
                    color: Colors.transparent,
                    textColor: const Color(0xFF374151),
                    onTap: () => _showPoDetailsDialog(context, po),
                    outlined: true,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Collapsed: show tap-to-expand hint
            InkWell(
              onTap: () => setState(() => _expandedPos.add(po.bulkPoId)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Individual RAE Orders',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${po.raeOrders.length} Orders',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRaeOrderRow(RaeOrderEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.raeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '₹${_fmtAmount(entry.totalAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${entry.raeCode} • ${entry.village}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              Text(
                '${entry.itemCount} items',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          Text(
            'Order: ${entry.orderId}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          if (entry.invoiceGenerated) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Invoice Generated',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          ...entry.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Text(
                    '• ${item.productName}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                  ),
                  const Spacer(),
                  Text(
                    '${item.quantity} ${item.unit}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Performance Summary
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPerformanceSummary() {
    return FutureBuilder<SupplierPerformance>(
      future: _service.getPerformance(_uid),
      builder: (context, snapshot) {
        final p = snapshot.data ??
            const SupplierPerformance(
              bulkPosProcessed: 12,
              totalRaeOrders: 145,
              onTimeDeliveryRate: 96,
              thisMonthRevenue: 1245000,
            );

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
                'Performance Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              _perfRow('Bulk POs Processed', '${p.bulkPosProcessed}'),
              _divider(),
              _perfRow('Total RAE Orders', '${p.totalRaeOrders}'),
              _divider(),
              _perfRow(
                'On-Time Delivery Rate',
                '${p.onTimeDeliveryRate.toStringAsFixed(0)}%',
                valueColor: _greenAccent,
              ),
              _divider(),
              _perfRow(
                'This Month Revenue',
                '₹${_fmtAmount(p.thisMonthRevenue)}',
                valueColor: _greenAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _perfRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFF3F4F6));

  // ─────────────────────────────────────────────────────────────────────────
  // FAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _greenFab,
      foregroundColor: Colors.white,
      onPressed: () => _showFabMenu(context),
      child: const Icon(Icons.menu, size: 26),
    );
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Manage Catalogue'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CatalogueManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('View Reports'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports – Coming Soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────────────────────────────────

  void _handleGenerateInvoices(BulkPurchaseOrder po) async {
    final orderIds = po.raeOrders.map((e) => e.orderId).toList();
    try {
      await _service.generateInvoices(orderIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoices generated for ${po.raeOrders.length} RAEs'),
            backgroundColor: _greenAccent,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDispatchDialog(BuildContext context, BulkPurchaseOrder po) {
    final driverNameCtrl = TextEditingController();
    final driverPhoneCtrl = TextEditingController();
    final vehicleNoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined,
                          color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Dispatch Control - Add Delivery Partner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter driver and vehicle information to create consignment manifest',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  // Orange info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Digital Paper Trail: ',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text:
                                'This information will be used to track the shipment and maintain logistics transparency throughout the delivery process.',
                            style: TextStyle(
                              color: Color(0xFFEA580C),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dialogField(
                    controller: driverNameCtrl,
                    label: 'Driver Name *',
                    hint: "Enter driver's full name",
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: driverPhoneCtrl,
                    label: 'Driver Phone Number *',
                    hint: 'Enter 10-digit mobile number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Enter valid phone';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: vehicleNoCtrl,
                    label: 'Vehicle Number *',
                    hint: 'e.g., TS09AB1234',
                    icon: Icons.directions_car_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Consignment details summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consignment Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PO: ${po.bulkPoId}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Total Packages: ${po.raeOrders.length}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Delivery Points: ${po.raeOrders.map((e) => e.village).join(', ')}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setS(() => isLoading = true);
                              try {
                                await _service.dispatchOrders(
                                  orderIds: po.raeOrders
                                      .map((e) => e.orderId)
                                      .toList(),
                                  driverName: driverNameCtrl.text.trim(),
                                  driverPhone: driverPhoneCtrl.text.trim(),
                                  vehicleNumber: vehicleNoCtrl.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Consignment created & dispatched!'),
                                      backgroundColor: Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setS(() => isLoading = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Create Consignment & Dispatch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF374151))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPoDetailsDialog(BuildContext context, BulkPurchaseOrder po) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(po.bulkPoId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District: ${po.district}'),
            Text('Date: ${_fmtDate(po.date)}'),
            Text('Status: ${_statusLabel(po.status)}'),
            Text('RAE Orders: ${po.totalRaeOrders}'),
            Text('Total Amount: ₹${_fmtAmount(po.totalAmount)}'),
            Text('Delivery Date: ${_fmtDate(po.deliveryDate)}'),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    final Color bg;
    final String label;
    switch (status) {
      case 'pending_invoices':
        bg = _orangeBadge;
        label = 'Pending Invoices';
        break;
      case 'ready_to_dispatch':
        bg = _blueBadge;
        label = 'Ready to Dispatch';
        break;
      case 'dispatched':
        bg = _greenAccent;
        label = 'Dispatched';
        break;
      default:
        bg = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_invoices': return 'Pending Invoices';
      case 'ready_to_dispatch': return 'Ready to Dispatch';
      case 'dispatched': return 'Dispatched';
      default: return status;
    }
  }

  Widget _infoChip(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        children: [
          TextSpan(text: label),
          const TextSpan(text: ' '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(icon, size: 18, color: textColor),
          label: Text(label, style: TextStyle(color: textColor)),
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _fmtAmount(double amount) {
    if (amount >= 100000) {
      // Format like ₹12,45,000 (Indian numbering)
      final str = amount.toStringAsFixed(0);
      if (str.length > 5) {
        final last3 = str.substring(str.length - 3);
        var rest = str.substring(0, str.length - 3);
        final parts = <String>[];
        while (rest.length > 2) {
          parts.insert(0, rest.substring(rest.length - 2));
          rest = rest.substring(0, rest.length - 2);
        }
        if (rest.isNotEmpty) parts.insert(0, rest);
        return '${parts.join(',')},$last3';
      }
      return str;
    }
    // Add commas for thousands
    final str = amount.toStringAsFixed(0);
    if (str.length > 3) {
      return str.replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return str;
  }
}
