import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/admin_access.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadPendingProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Products'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadPendingProducts(),
          ),
        ],
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminProductsPendingLoaded) {
            if (state.products.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Uicons.boxOpen, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No pending products'),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              itemBuilder: (context, index) =>
                  _productCard(context, state.products[index]),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCubit>().loadPendingProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!_isReloading) {
            _isReloading = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AdminCubit>().loadPendingProducts();
              _isReloading = false;
            });
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _productCard(BuildContext context, Map<String, dynamic> product) {
    final id = product['id']?.toString() ?? '';
    final name = product['name']?.toString() ?? 'Unknown';
    final sku = product['sku']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final currency = product['currency']?.toString() ?? 'TZS';
    final sellerName = product['seller_name']?.toString() ??
        product['seller']?['business_name']?.toString() ?? 'Unknown Seller';
    final images = product['images'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[0]?.toString() ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(Uicons.image, size: 24),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Uicons.image, size: 24, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('SKU: $sku', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Seller: $sellerName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('$currency $price', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (images.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Uicons.triangleWarning, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text('No images — cannot approve',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                  ],
                ),
              )
            else
            Row(
              children: [
                if (AdminAccess.canAccessItem(
                        GetIt.instance<TokenStorage>().currentUser,
                        'products.approve'))
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, foregroundColor: Colors.white),
                      icon: const Icon(Uicons.checkCircle, size: 16),
                      label: const Text('Approve'),
                      onPressed: () => _confirmApprove(context, id, name),
                    ),
                  ),
                if (AdminAccess.canAccessItem(
                        GetIt.instance<TokenStorage>().currentUser,
                        'products.approve') &&
                    AdminAccess.canAccessItem(
                        GetIt.instance<TokenStorage>().currentUser,
                        'products.reject'))
                  const SizedBox(width: 12),
                if (AdminAccess.canAccessItem(
                        GetIt.instance<TokenStorage>().currentUser,
                        'products.reject'))
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, foregroundColor: Colors.white),
                      icon: const Icon(Uicons.circleXmark, size: 16),
                      label: const Text('Reject'),
                      onPressed: () => _showRejectDialog(context, id, name),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(BuildContext context, String productId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Product?'),
        content: Text('Approve "$name" for the marketplace?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCubit>().approveProduct(productId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String productId, String name) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "$name"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminCubit>().rejectProduct(productId, reasonController.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
