import 'package:flutter/material.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/uicons.dart';
import '../../../customer/data/models/product_model.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool reset = true}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.myProducts, queryParameters: {
        'page': _page,
        'page_size': 20,
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
      });

      final data = response.data;
      final List results = data is List ? data : (data['results'] as List? ?? []);
      final total = data is Map ? (data['total'] as int? ?? results.length) : results.length;
      _hasMore = _page * 20 < total;

      final newProducts = results.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        if (reset) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.plus),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Uicons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Uicons.crossSmall),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _loadProducts(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadProducts, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Uicons.tags, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('No products yet', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddProductDialog(context),
                                  icon: const Icon(Uicons.plus),
                                  label: const Text('Add Product'),
                                ),
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification &&
                                  notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
                                  _hasMore) {
                                _page++;
                                _loadProducts(reset: false);
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _products.length,
                              itemBuilder: (context, index) => _buildProductCard(context, _products[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final statusColor = _getStatusColor(product.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.thumbnailUrl != null
                  ? Image.network(
                      product.thumbnailUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(product.formattedPrice,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.rejectionReason != null)
                        Expanded(
                          child: Text(
                            product.rejectionReason!,
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Uicons.edit, size: 18),
              onPressed: () => _showEditProductDialog(context, product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: const Icon(Uicons.image, color: Colors.grey, size: 24),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductFormDialog(context, null);
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    _showProductFormDialog(context, product);
  }

  void _showProductFormDialog(BuildContext context, ProductModel? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(text: existing?.price.toStringAsFixed(0) ?? '');
    final salePriceController = TextEditingController(text: existing?.salePrice?.toStringAsFixed(0) ?? '');
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final weightController = TextEditingController(text: existing?.weight ?? '');
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId = existing?.categoryId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (TZS) *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: salePriceController,
                  decoration: const InputDecoration(labelText: 'Sale Price (optional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Weight', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await _saveProduct(
                  existing: existing,
                  name: nameController.text.trim(),
                  sku: skuController.text.trim(),
                  price: double.tryParse(priceController.text.trim()) ?? 0,
                  salePrice: salePriceController.text.trim().isNotEmpty
                      ? double.tryParse(salePriceController.text.trim())
                      : null,
                  description: descController.text.trim(),
                  weight: weightController.text.trim(),
                  categoryId: selectedCategoryId,
                );
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct({
    ProductModel? existing,
    required String name,
    required String sku,
    required double price,
    double? salePrice,
    String? description,
    String? weight,
    String? categoryId,
  }) async {
    try {
      final client = sl<ApiClient>();
      final data = <String, dynamic>{
        'name': name,
        'sku': sku,
        'price': price,
        if (salePrice != null) 'sale_price': salePrice,
        if (description != null && description.isNotEmpty) 'description': description,
        if (weight != null && weight.isNotEmpty) 'weight': weight,
        if (categoryId != null) 'category_id': categoryId,
      };

      if (existing != null) {
        await client.patch(ApiConstants.productById(existing.id), data: data);
      } else {
        await client.post(ApiConstants.products, data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? 'Product created' : 'Product updated'), backgroundColor: Colors.green),
        );
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return Colors.green;
      case 'pending':
      case 'pending_review':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
