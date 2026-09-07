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

  ApiClient get client => sl<ApiClient>();

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

  Future<void> _archiveProduct(ProductModel product) async {
    try {
      await client.patch(ApiConstants.productById(product.id), data: {
        'status': 'archived',
      });
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} archived'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    try {
      await client.delete(ApiConstants.productById(product.id));
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} deleted'), backgroundColor: const Color(0xFF22C55E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _showArchiveConfirmation(BuildContext context, ProductModel product) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.archive, color: Color(0xFFF59E0B), size: 28),
            ),
            const SizedBox(height: 20),
            Text('Archive Product?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text('Archive "${product.name}"? It will be hidden from your store but can be restored later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _archiveProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Archive', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Uicons.trash, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 20),
            Text('Delete Product?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text('Permanently delete "${product.name}"? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          // Search + Add
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Uicons.crossSmall, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                              onPressed: () { _searchController.clear(); _loadProducts(); },
                            )
                          : null,
                      filled: true,
                      fillColor: cs.onSurface.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _loadProducts(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showProductDrawer(context, null),
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Uicons.plus, color: Colors.white, size: 22),
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
                            Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
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
                                Icon(Uicons.box, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text('No products yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showProductDrawer(context, null),
                                  icon: const Icon(Uicons.plus),
                                  label: const Text('Add Product'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadProducts(),
                            child: NotificationListener<ScrollNotification>(
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
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                                itemCount: _products.length,
                                itemBuilder: (context, index) => _buildProductCard(context, _products[index]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(product.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProductDrawer(context, product),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppNetworkImage(
                    imageUrl: product.thumbnailUrl,
                    width: 56, height: 56,
                    borderRadius: 10,
                    placeholderIcon: Uicons.box,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(product.formattedPrice,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                // Status dot
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                // Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  padding: EdgeInsets.zero,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Uicons.edit, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Text('Edit', style: TextStyle(fontSize: 14, color: cs.onSurface)),
                    ])),
                    PopupMenuItem(value: 'archive', child: Row(children: [
                      Icon(Icons.archive, size: 16, color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Text('Archive', style: const TextStyle(fontSize: 14, color: Color(0xFFF59E0B))),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Uicons.trash, size: 16, color: const Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Text('Delete', style: const TextStyle(fontSize: 14, color: Color(0xFFEF4444))),
                    ])),
                  ],
                  onSelected: (action) {
                    if (action == 'edit') _showProductDrawer(context, product);
                    if (action == 'archive') _showArchiveConfirmation(context, product);
                    if (action == 'delete') _showDeleteConfirmation(context, product);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        return const Color(0xFF22C55E);
      case 'pending':
      case 'pending_review':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'draft':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
