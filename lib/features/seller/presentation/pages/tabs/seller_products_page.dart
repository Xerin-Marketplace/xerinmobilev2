import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().refreshProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddProductDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSearchBar(colorScheme),
                const SizedBox(height: 12),
                _buildFilterChips(colorScheme),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<SellerCubit, SellerState>(
              builder: (context, state) {
                if (state is SellerDashboardLoaded) {
                  final products = _filterProducts(state.products);
                  if (products.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<SellerCubit>().refreshProducts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(product, colorScheme);
                      },
                    ),
                  );
                }
                if (state is SellerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildEmptyState(colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterProducts(List<Map<String, dynamic>> products) {
    var filtered = products;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((p) {
        final status = p['status'] as String? ?? 'active';
        final isActive = p['is_active'] as bool? ?? true;
        if (_selectedFilter == 'Active') return isActive;
        if (_selectedFilter == 'Inactive') return !isActive;
        if (_selectedFilter == 'Pending') return status == 'pending';
        return true;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    }
    return filtered;
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          prefixIcon: Icon(Icons.search_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.35), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    final filters = ['All', 'Active', 'Inactive', 'Pending'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isActive = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, ColorScheme colorScheme) {
    final name = product['name'] as String? ?? 'Unknown';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final currency = product['currency'] as String? ?? 'TZS';
    final status = product['status'] as String? ?? 'active';
    final isActive = product['is_active'] as bool? ?? true;
    final productId = product['id']?.toString() ?? '';

    final statusColor = status == 'approved' || isActive
        ? const Color(0xFF22C55E)
        : status == 'pending'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE53935);

    final formattedPrice = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currency $formattedPrice',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showEditProductDialog(context, product),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showDeleteConfirm(context, productId, name),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18, color: colorScheme.error.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add" to create your first product',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductFormDialog(context, isEdit: false);
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
    _showProductFormDialog(context, isEdit: true, product: product);
  }

  void _showProductFormDialog(BuildContext context,
      {required bool isEdit, Map<String, dynamic>? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] as String? ?? '');
    final skuCtrl = TextEditingController(text: product?['sku'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: product?['price']?.toString() ?? '');
    final descCtrl = TextEditingController(
        text: product?['description'] as String? ?? '');
    final slugCtrl = TextEditingController(text: product?['slug'] as String? ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Product Name'),
              const SizedBox(height: 12),
              _dialogField(skuCtrl, 'SKU'),
              const SizedBox(height: 12),
              _dialogField(slugCtrl, 'Slug'),
              const SizedBox(height: 12),
              _dialogField(priceCtrl, 'Price', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _dialogField(descCtrl, 'Description', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = <String, dynamic>{
                'name': nameCtrl.text,
                'sku': skuCtrl.text,
                'slug': slugCtrl.text.isNotEmpty
                    ? slugCtrl.text
                    : nameCtrl.text.toLowerCase().replaceAll(' ', '-'),
                'price': double.tryParse(priceCtrl.text) ?? 0.0,
                'description': descCtrl.text,
              };
              Navigator.pop(dialogContext);
              if (isEdit && product != null) {
                context.read<SellerCubit>().updateProduct(
                      product['id'].toString(),
                      data,
                    );
              } else {
                context.read<SellerCubit>().createProduct(data);
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String productId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SellerCubit>().deleteProduct(productId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
