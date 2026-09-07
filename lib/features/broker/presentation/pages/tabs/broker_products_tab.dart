import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/notifications/notification_service.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../data/models/broker_models.dart';
import '../../cubit/broker_cubit.dart';

class BrokerProductsTab extends StatefulWidget {
  const BrokerProductsTab({super.key});

  @override
  State<BrokerProductsTab> createState() => _BrokerProductsTabState();
}

class _BrokerProductsTabState extends State<BrokerProductsTab> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<BrokerCubit, BrokerState>(
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
          return _buildList(context, state.products, cs);
        }
        if (state is BrokerError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(BuildContext context, List<BrokerProductModel> products, ColorScheme cs) {
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Uicons.box, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text('No products yet.\nCreate 24-hour listings to sell directly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  NotificationService().info(
                      'Product creation will be available in the next update. Please use the web dashboard.');
                },
                icon: const Icon(Uicons.plus, size: 18),
                label: const Text('Create Product'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadProducts(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.primaryImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Uicons.image, color: cs.primary, size: 24)),
                      )
                    : Icon(Uicons.image, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${product.currency} ${product.price}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.primary)),
                const SizedBox(height: 4),
                Row(children: [
                  _statusBadge(product.status, cs),
                  const SizedBox(width: 8),
                  Text('Qty: ${product.availableQuantity}',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                ]),
              ])),
              if (product.status == 'draft')
                IconButton(
                  icon: Icon(Uicons.upload, color: cs.primary, size: 18),
                  onPressed: () => context.read<BrokerCubit>().publishProduct(product.id),
                  tooltip: 'Publish',
                ),
            ]),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status, ColorScheme cs) {
    final colors = {
      'active': const Color(0xFF22C55E),
      'draft': const Color(0xFF9CA3AF),
      'expired': const Color(0xFFEF4444),
      'rejected': const Color(0xFFEF4444),
      'pending': const Color(0xFFF59E0B),
    };
    final color = colors[status] ?? const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
