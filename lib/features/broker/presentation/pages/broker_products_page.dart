import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

class BrokerProductsPage extends StatefulWidget {
  const BrokerProductsPage({super.key});

  @override
  State<BrokerProductsPage> createState() => _BrokerProductsPageState();
}

class _BrokerProductsPageState extends State<BrokerProductsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<BrokerCubit>().loadProducts(),
          ),
        ],
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerActionSuccess) {
            NotificationService().success(state.message);
          } else if (state is BrokerError) {
            NotificationService().error(state.message);
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerProductsLoaded) {
            return _buildList(context, state.products, colorScheme);
          }
          if (state is BrokerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BrokerCubit>().loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<BrokerProductModel> products,
    ColorScheme colorScheme,
  ) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Uicons.box, size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                'No products yet.\nCreate 24-hour listings to sell directly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  NotificationService().info(
                      'Product creation will be available in the next update. Please use the web dashboard.');
                },
                icon: const Icon(Uicons.plus, size: 18),
                label: const Text('Create Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadProducts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.primaryImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Uicons.image, color: colorScheme.primary),
                          ),
                        )
                      : Icon(Uicons.image, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.currency} ${product.price}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _statusBadge(product.status, colorScheme),
                          const SizedBox(width: 8),
                          Text(
                            'Qty: ${product.availableQuantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (product.status == 'draft')
                  IconButton(
                    icon: Icon(Uicons.upload, color: colorScheme.primary, size: 20),
                    onPressed: () {
                      context.read<BrokerCubit>().publishProduct(product.id);
                    },
                    tooltip: 'Publish',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status, ColorScheme colorScheme) {
    final colors = {
      'active': Colors.green,
      'draft': Colors.grey,
      'expired': Colors.red,
      'rejected': Colors.red,
      'pending': Colors.orange,
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
