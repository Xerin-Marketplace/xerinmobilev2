import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';
import '../../cubit/admin_state.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is AdminError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminCubit>().loadDashboard(),
          );
        }

        if (state is! AdminDashboardLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = state.pendingProducts;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No pending products',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('All products have been reviewed',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AdminCubit>().loadDashboard(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final name = product['name']?.toString() ?? 'Unknown Product';
              final price = product['price']?.toString() ?? '0';
              final sellerName = product['seller_name']?.toString() ??
                  product['seller']?['business_name']?.toString() ??
                  'Unknown Seller';
              final id = product['id']?.toString() ?? '';
              final description = product['description']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.2),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.teal),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TZS $price',
                          style: const TextStyle(fontSize: 13)),
                      Text('by $sellerName',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7))),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Approve'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () => context
                                      .read<AdminCubit>()
                                      .approveProduct(id),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  onPressed: () => _showRejectDialog(
                                      context, id),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, String id) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Product'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<AdminCubit>()
                  .rejectProduct(id, reason: reasonCtrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Failed to load products',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
