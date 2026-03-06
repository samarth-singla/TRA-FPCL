import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import 'shopping_cart_screen.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('name', ascending: true);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch = product['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' ||
          product['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Set<String> get _categories {
    final cats = _products
        .map((p) => p['category'].toString())
        .toSet();
    return {'All', ...cats};
  }

  static const _green = Color(0xFF2E9B33);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cartService),
            _buildFilterRow(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No products found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _buildProductCard(product, cartService);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartService cartService) {
    return Container(
      color: _green,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 12, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Product Catalog',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white, size: 26),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ShoppingCartScreen())),
                    ),
                    if (cartService.itemCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '${cartService.itemCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle:
                      TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                  prefixIcon:
                      Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isDense: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? 'All'),
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, size: 18, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, CartService cartService) {
    final productId = product['id'].toString();
    final name = product['name']?.toString() ?? 'Unknown Product';
    final price = (product['price'] ?? 0).toDouble();
    final stock = product['stock_quantity'] ?? 0;
    final unit = product['unit']?.toString() ?? 'unit';
    final category = product['category']?.toString() ?? 'General';
    final supplier = product['supplier_name']?.toString() ?? '';
    final isInStock = stock > 0;
    final quantityInCart = cartService.getProductQuantity(productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isInStock
                      ? _green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_bag,
                    color: isInStock ? _green : Colors.grey, size: 26),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(category,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _green)),
                        Text(' / $unit',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ],
                ),
              ),
              // Stock badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInStock
                      ? const Color(0xFF212121)
                      : const Color(0xFF9E9E9E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInStock ? 'Available' : 'Out of Stock',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (supplier.isNotEmpty) ...
            [
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.store_outlined,
                      size: 13, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 4),
                  Text(supplier,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Certified',
                        style: TextStyle(
                            fontSize: 10,
                            color: _green,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          const SizedBox(height: 12),
          // Cart controls
          quantityInCart > 0
              ? Row(
                  children: [
                    IconButton(
                      onPressed: () => cartService.updateQuantity(
                          productId, quantityInCart - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$quantityInCart in cart',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: _green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isInStock && quantityInCart < stock
                          ? () => cartService.updateQuantity(
                              productId, quantityInCart + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: _green,
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isInStock
                        ? () {
                            cartService.addToCart(
                              productId: productId,
                              productName: name,
                              price: price,
                              unit: unit,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$name added to cart'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
