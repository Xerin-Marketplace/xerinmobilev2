import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/broker_models.dart';
import '../cubit/broker_cubit.dart';

class MawingaStorePage extends StatefulWidget {
  const MawingaStorePage({super.key});

  @override
  State<MawingaStorePage> createState() => _MawingaStorePageState();
}

class _MawingaStorePageState extends State<MawingaStorePage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadDashboard();
    context.read<BrokerCubit>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Digital Store'),
      ),
      body: SafeArea(
        child: BlocConsumer<BrokerCubit, BrokerState>(
          listener: (context, state) {
            if (state is BrokerError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is BrokerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BrokerDashboardLoaded) {
              final broker = state.broker;
              final storeName = '${broker.firstName ?? 'My'}\'s Store';
              return RefreshIndicator(
                onRefresh: () async => context.read<BrokerCubit>().loadProducts(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStoreHeader(storeName, broker.brokerCode, cs),
                    const SizedBox(height: 20),
                    _buildStoreStats(cs),
                    const SizedBox(height: 20),
                    Text('Products in Store',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    const SizedBox(height: 12),
                    _buildProductsList(context, cs),
                  ],
                ),
              );
            }
            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  Widget _buildStoreHeader(String storeName, String brokerCode, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Uicons.shop, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mawinga ID: $brokerCode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Powered by Xerin Marketplace',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStats(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _statCard('Products', '0', Uicons.box, cs),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard('Orders', '0', Uicons.shoppingBag, cs),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard('Reviews', '0', Uicons.star, cs),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, ColorScheme cs) {
    return BlocBuilder<BrokerCubit, BrokerState>(
      builder: (context, state) {
        if (state is BrokerProductsLoaded) {
          final products = state.products;
          if (products.isEmpty) {
            return _buildEmptyProducts(context, cs);
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductTile(product, cs);
            },
          );
        }
        return _buildEmptyProducts(context, cs);
      },
    );
  }

  Widget _buildProductTile(BrokerProductModel product, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: product.primaryImageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(
                      product.primaryImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        child: Center(child: Icon(Uicons.box, size: 32, color: cs.onSurface.withValues(alpha: 0.2))),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Center(child: Icon(Uicons.box, size: 32, color: cs.onSurface.withValues(alpha: 0.2))),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price} ${product.currency}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Uicons.boxOpen, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('No products yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text(
            'Add your own products or select from Find Products to populate your store.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.icon(
                onPressed: () => context.push(AppConstants.brokerProductsRoute),
                icon: Icon(Uicons.plus, size: 16),
                label: const Text('Add Product'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(AppConstants.mawingaFindProductsRoute),
                icon: Icon(Uicons.search, size: 16),
                label: const Text('Find Products'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
