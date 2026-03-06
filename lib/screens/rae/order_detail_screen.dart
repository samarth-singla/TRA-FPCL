import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Full order detail screen for RAE users.
/// Shows 4-step progress stepper, item list, supplier info, and admin notes.
class OrderDetailScreen extends StatefulWidget {
  /// Raw UUID from the orders table. Empty string for demo orders.
  final String orderId;

  /// Human-readable display id (e.g. '#A1B2C3D4' or 'ORD1234').
  final String displayId;

  /// When true, shows realistic demo data without Supabase calls.
  final bool isDemo;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.displayId,
    this.isDemo = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _green = Color(0xFF2E9B33);

  final _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Order fields
  String _status = 'pending';
  String _createdAt = '';
  double _subtotal = 0;
  double _gstAmount = 0;
  double _totalAmount = 0;

  // Notes-parsed fields
  String? _approvedBy;
  String? _approvedAt;
  String? _supplierName;
  String? _driverName;
  String? _vehicleNumber;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.isDemo) {
      _loadDemo();
    } else {
      _loadOrder();
    }
  }

  void _loadDemo() {
    setState(() {
      _status = 'dispatched';
      _createdAt = '2024-06-01';
      _subtotal = 4120.0;
      _gstAmount = 460.0;
      _totalAmount = 4580.0;
      _approvedBy = 'Admin User';
      _approvedAt = '2024-06-02';
      _supplierName = 'AgriTech Suppliers Ltd.';
      _driverName = 'Raju Yadav';
      _vehicleNumber = 'TS09 AB 1234';
      _items = [
        {'product_name': 'DAP Fertilizer', 'quantity': 2, 'price_per_unit': 1200.0, 'total_price': 2400.0},
        {'product_name': 'Urea', 'quantity': 3, 'price_per_unit': 580.0, 'total_price': 1740.0},
      ];
      _loading = false;
    });
  }

  Future<void> _loadOrder() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fetch order row
      final order = await _supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .maybeSingle();

      if (order == null) {
        setState(() { _error = 'Order not found.'; _loading = false; });
        return;
      }

      // Fetch item rows
      final itemRows = await _supabase
          .from('order_items')
          .select('product_name, quantity, price_per_unit, total_price')
          .eq('order_id', widget.orderId);

      // Parse notes JSON
      final notes = order['notes']?.toString() ?? '';
      String? approvedBy, approvedAt, supplierName, driverName, vehicleNumber;
      if (notes.isNotEmpty) {
        approvedBy = RegExp(r'"approved_by":"([^"]+)"').firstMatch(notes)?.group(1);
        approvedAt = RegExp(r'"approved_at":"([^"]+)"').firstMatch(notes)?.group(1);
        final rawSupplier = RegExp(r'"supplier_name":"([^"]*)"').firstMatch(notes)?.group(1);
        supplierName = (rawSupplier?.isNotEmpty == true) ? rawSupplier : null;
        driverName = RegExp(r'"driver":"([^"]*)"').firstMatch(notes)?.group(1);
        vehicleNumber = RegExp(r'"vehicle":"([^"]*)"').firstMatch(notes)?.group(1);
      }

      if (mounted) {
        setState(() {
          _status = order['status']?.toString() ?? 'pending';
          _createdAt = _fmtIso(order['created_at']?.toString() ?? '');
          _subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
          _gstAmount = (order['gst_amount'] as num?)?.toDouble() ?? 0;
          _totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
          _approvedBy = approvedBy;
          _approvedAt = approvedAt != null ? _fmtIso(approvedAt) : null;
          _supplierName = supplierName;
          _driverName = driverName;
          _vehicleNumber = vehicleNumber;
          _items = (itemRows as List).map((r) => Map<String, dynamic>.from(r)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ─── Step index helpers ────────────────────────────────────────────────────

  int get _currentStep {
    switch (_status) {
      case 'pending': return 0;
      case 'confirmed': return 1;
      case 'dispatched': return 2;
      case 'delivered': return 3;
      case 'cancelled': return -1;
      default: return 0;
    }
  }

  bool _stepDone(int step) => _currentStep >= step && _currentStep >= 0;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrder,
                          style: ElevatedButton.styleFrom(backgroundColor: _green),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.isDemo ? () async {} : _loadOrder,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusStepper(),
                      const SizedBox(height: 16),
                      _buildItemsCard(),
                      const SizedBox(height: 16),
                      _buildAmountCard(),
                      if (_approvedBy != null) ...[
                        const SizedBox(height: 16),
                        _buildApprovalCard(),
                      ],
                      if (_supplierName != null || _driverName != null) ...[
                        const SizedBox(height: 16),
                        _buildDispatchCard(),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _status == 'cancelled' ? Colors.red[700] : _green,
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayId,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                if (_createdAt.isNotEmpty)
                  Text(
                    'Placed on $_createdAt',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          _headerBadge(),
        ],
      ),
    );
  }

  Widget _headerBadge() {
    final label = _statusLabel(_status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white54),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  // ─── 4-Step Progress Stepper ──────────────────────────────────────────────

  Widget _buildStatusStepper() {
    if (_status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('This order was cancelled.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final steps = [
      _StepData(
        label: 'Placed',
        icon: Icons.receipt_long_outlined,
        detail: _createdAt.isNotEmpty ? 'Order placed $_createdAt' : null,
      ),
      _StepData(
        label: 'Approved',
        icon: Icons.check_circle_outline,
        detail: _approvedBy != null
            ? 'By $_approvedBy${_approvedAt != null ? ' on $_approvedAt' : ''}'
            : null,
      ),
      _StepData(
        label: 'Dispatched',
        icon: Icons.local_shipping_outlined,
        detail: _vehicleNumber != null ? 'Vehicle: $_vehicleNumber' : null,
      ),
      _StepData(
        label: 'Delivered',
        icon: Icons.home_outlined,
        detail: _status == 'delivered' ? 'Order delivered' : null,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text('Order Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 20),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _stepCircle(i, steps[i]),
                if (i < steps.length - 1) _stepConnector(i),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Labels row
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Text(
                    steps[i].label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: _stepDone(i) ? FontWeight.w600 : FontWeight.normal,
                      color: _stepDone(i) ? _green : const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Current step detail text
          if (_currentStep >= 0 && _currentStep < steps.length &&
              steps[_currentStep].detail != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                steps[_currentStep].detail!,
                style: const TextStyle(fontSize: 12, color: _green),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepCircle(int index, _StepData step) {
    final done = _stepDone(index);
    final current = _currentStep == index;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _green : const Color(0xFFE0E0E0),
              border: current
                  ? Border.all(color: _green, width: 2.5)
                  : null,
            ),
            child: Icon(
              done ? Icons.check : step.icon,
              color: done ? Colors.white : const Color(0xFFBDBDBD),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepConnector(int index) {
    final filled = _currentStep > index;
    return Expanded(
      flex: 2,
      child: Container(
        height: 3,
        color: filled ? _green : const Color(0xFFE0E0E0),
      ),
    );
  }

  // ─── Items Card ────────────────────────────────────────────────────────────

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: _green),
              const SizedBox(width: 8),
              Text(
                'Order Items (${_items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            const Text('No item details available.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13))
          else
            for (final item in _items) ...[
              _itemRow(item),
              if (item != _items.last)
                const Divider(height: 16, color: Color(0xFFF0F0F0)),
            ],
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final name = item['product_name']?.toString() ?? 'Unknown';
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final ppu = (item['price_per_unit'] as num?)?.toDouble() ?? 0;
    final total = (item['total_price'] as num?)?.toDouble() ?? (qty * ppu);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _green,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              Text('₹${ppu.toStringAsFixed(0)} × $qty',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
        Text(
          '₹${total.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121)),
        ),
      ],
    );
  }

  // ─── Amount Card ───────────────────────────────────────────────────────────

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Row(
            children: [
              Icon(Icons.receipt_outlined, size: 18, color: _green),
              SizedBox(width: 8),
              Text('Bill Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          _amountRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}',
              isSubtle: true),
          const SizedBox(height: 4),
          _amountRow('GST (18%)', '₹${_gstAmount.toStringAsFixed(0)}',
              isSubtle: true),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          _amountRow('Total Amount', '₹${_totalAmount.toStringAsFixed(0)}',
              isBold: true, color: _green),
        ],
      ),
    );
  }

  Widget _amountRow(String label, String value,
      {bool isSubtle = false, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isSubtle ? const Color(0xFF9E9E9E) : const Color(0xFF212121))),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 16 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? const Color(0xFF212121))),
      ],
    );
  }

  // ─── Approval Info Card ────────────────────────────────────────────────────

  Widget _buildApprovalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_outlined, color: _green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Approved',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _green)),
                if (_approvedBy != null)
                  Text('Approved by: $_approvedBy',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF374151))),
                if (_approvedAt != null)
                  Text('Date: $_approvedAt',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                if (_supplierName != null)
                  Text('Assigned to: $_supplierName',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dispatch/Delivery Info Card ──────────────────────────────────────────

  Widget _buildDispatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
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
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  size: 18, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text('Dispatch Details',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1565C0))),
            ],
          ),
          const SizedBox(height: 12),
          if (_supplierName != null)
            _infoRow(Icons.store_outlined, 'Supplier', _supplierName!),
          if (_driverName != null)
            _infoRow(Icons.person_outlined, 'Driver', _driverName!),
          if (_vehicleNumber != null)
            _infoRow(Icons.directions_car_outlined, 'Vehicle', _vehicleNumber!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212121))),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Approved';
      case 'dispatched': return 'Dispatched';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String _fmtIso(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StepData {
  final String label;
  final IconData icon;
  final String? detail;
  const _StepData({required this.label, required this.icon, this.detail});
}
