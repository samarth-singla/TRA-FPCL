import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';

/// Catalogue Management Screen
///
/// Matches the mockscreen:
///   – Purple-indigo header with "Back to Dashboard" + title
///   – 3 stat cards: Total Products, Active Items, Categories
///   – Search + "+ Add" button row
///   – Horizontal category filter chips
///   – Expandable product cards with Deactivate / Edit / Delete actions
class CatalogueManagementScreen extends StatefulWidget {
  const CatalogueManagementScreen({super.key});

  @override
  State<CatalogueManagementScreen> createState() =>
      _CatalogueManagementScreenState();
}

class _CatalogueManagementScreenState
    extends State<CatalogueManagementScreen> {
  final _service = SupplierService();

  // ── Colour palette ─────────────────────────────────────────────────────
  static const _indigo = Color(0xFF4F46E5);
  static const _indigoDeep = Color(0xFF3730A3);
  static const _greenActive = Color(0xFF16A34A);

  // ── State ──────────────────────────────────────────────────────────────
  List<SupplierProduct> _products = [];
  List<SupplierProduct> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();

  static const _categories = [
    'All',
    'Seeds',
    'Fertilizers',
    'Pesticides',
    'Bio Products',
    'Farm Tools',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _service.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    _filtered = _products.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ── Stats derived from products ─────────────────────────────────────────
  int get _totalProducts => _products.length;
  int get _activeItems => _products.where((p) => p.isActive).length;
  int get _categoriesCount =>
      _products.map((p) => p.category).toSet().length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatCards(),
                              const SizedBox(height: 16),
                              _buildSearchAndAdd(context),
                              const SizedBox(height: 12),
                              _buildCategoryChips(),
                              const SizedBox(height: 16),
                              ..._buildProductCards(context),
                              if (_filtered.isEmpty)
                                _emptyState(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_indigo, _indigoDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  'Back to Dashboard',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Catalogue Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Manage your product inventory and pricing',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stat Cards
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    return Row(
      children: [
        _miniStatCard(
          value: '$_totalProducts',
          label: 'Total Products',
          valueColor: _indigo,
        ),
        const SizedBox(width: 10),
        _miniStatCard(
          value: '$_activeItems',
          label: 'Active Items',
          valueColor: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 10),
        _miniStatCard(
          value: '$_categoriesCount',
          label: 'Categories',
          valueColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search + Add
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchAndAdd(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
                _applyFilter();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _indigo),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(context, null),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _indigo,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category Chips
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _applyFilter();
                });
              },
              selectedColor: _indigo,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _indigo : const Color(0xFFD1D5DB),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Product Cards
  // ─────────────────────────────────────────────────────────────────────────

  List<Widget> _buildProductCards(BuildContext context) {
    return _filtered
        .map((product) => _buildProductCard(context, product))
        .toList();
  }

  Widget _buildProductCard(BuildContext context, SupplierProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // ── Product header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? _greenActive
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.isActive ? 'active' : 'inactive',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _greenActive,
                          ),
                        ),
                        Text(
                          'per ${product.unit}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.label_outline,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const Text(
                      ' • ',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                    Text(
                      'Stock: ${product.stockQuantity}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // ── Details grid ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _detailRow('GST Rate:', '18%'),
                ),
                Expanded(
                  child: _detailRow(
                      'Min Order:', '1 ${product.unit}'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _detailRow(
                      'Product ID:', product.id.substring(0, 8).toUpperCase()),
                ),
                Expanded(
                  child: _detailRow('Unit:', product.unit),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // ── Action buttons ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _handleToggleActive(context, product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      product.isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddEditDialog(context, product),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleDelete(context, product),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child:
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        children: [
          TextSpan(text: label),
          const TextSpan(text: ' '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  void _handleToggleActive(
      BuildContext context, SupplierProduct product) async {
    try {
      await _service.toggleProductActive(product.id, !product.isActive);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(product.isActive
                ? '${product.name} deactivated'
                : '${product.name} activated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleDelete(BuildContext context, SupplierProduct product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteProduct(product.id);
                await _loadProducts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add / Edit Dialog
  // ─────────────────────────────────────────────────────────────────────────

  void _showAddEditDialog(BuildContext context, SupplierProduct? product) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(0) : '');
    final unitCtrl = TextEditingController(text: product?.unit ?? '');
    final stockCtrl = TextEditingController(
        text: product != null ? '${product.stockQuantity}' : '');
    String selectedCat = product?.category ?? 'Seeds';
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formField(
                    controller: nameCtrl,
                    label: 'Product Name *',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    controller: descCtrl,
                    label: 'Description',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Category dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    decoration: _inputDecoration('Category *'),
                    items: _categories
                        .where((c) => c != 'All')
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => selectedCat = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _formField(
                          controller: priceCtrl,
                          label: 'Price (₹) *',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (double.tryParse(v.trim()) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _formField(
                          controller: unitCtrl,
                          label: 'Unit *',
                          hint: 'e.g., kg, packet',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _formField(
                    controller: stockCtrl,
                    label: 'Stock Quantity *',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isLoading = true);
                      try {
                        if (isEdit) {
                          await _service.updateProduct(
                            productId: product.id,
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: selectedCat,
                            price: double.parse(priceCtrl.text.trim()),
                            unit: unitCtrl.text.trim(),
                            stockQuantity:
                                int.parse(stockCtrl.text.trim()),
                          );
                        } else {
                          await _service.addProduct(
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: selectedCat,
                            price: double.parse(priceCtrl.text.trim()),
                            unit: unitCtrl.text.trim(),
                            stockQuantity:
                                int.parse(stockCtrl.text.trim()),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadProducts();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Product updated'
                                  : 'Product added'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        }
                      } catch (e) {
                        setS(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _indigo,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _indigo),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products match "$_searchQuery"'
                  : 'No products in this category',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
