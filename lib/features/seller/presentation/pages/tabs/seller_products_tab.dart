import 'package:flutter/material.dart';

import '../../../../../config/constants/api_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../../customer/data/models/product_model.dart';
import '../../../../../shared/widgets/app_network_image.dart';
import '../../widgets/seller_product_drawer.dart';

class SellerProductsTab extends StatefulWidget {
  const SellerProductsTab({super.key});

  @override
  State<SellerProductsTab> createState() => _SellerProductsTabState();
}

class _SellerProductsTabState extends State<SellerProductsTab> {
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Uicons.plus),
                onPressed: () => _showAddProductDrawer(context),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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
                                onPressed: () => _showAddProductDrawer(context),
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
            AppNetworkImage(
              imageUrl: product.thumbnailUrl,
              width: 64,
              height: 64,
              borderRadius: 10,
              placeholderIcon: Uicons.box,
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
              onPressed: () => _showEditProductDrawer(context, product),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDrawer(BuildContext context) {
    _showProductDrawer(context, null);
  }

  void _showEditProductDrawer(BuildContext context, ProductModel product) {
    _showProductDrawer(context, product);
  }

  void _showProductDrawer(BuildContext context, ProductModel? existing) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SellerProductDrawer(
          existing: existing,
          onSaved: _loadProducts,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
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
