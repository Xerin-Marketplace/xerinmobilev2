import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../data/models/product_model.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

class WholesalePage extends StatefulWidget {
  const WholesalePage({super.key});

  @override
  State<WholesalePage> createState() => _WholesalePageState();
}

class _WholesalePageState extends State<WholesalePage> {
  String _sortBy = 'popular';

  static const _tiers = [
    {'range': '1–9 units', 'label': 'Retail', 'discount': '0%', 'color': Color(0xFF6B7280)},
    {'range': '10–49 units', 'label': 'Wholesale L1', 'discount': '10%', 'color': Color(0xFF3B82F6)},
    {'range': '50–99 units', 'label': 'Wholesale L2', 'discount': '20%', 'color': Color(0xFF00A651)},
    {'range': '100+ units', 'label': 'Custom Quote', 'discount': 'Custom', 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(cs),
                    const SizedBox(height: 20),
                    _buildInfoBanner(cs),
                    const SizedBox(height: 24),
                    _buildTieredPricingCard(cs),
                    const SizedBox(height: 24),
                    _buildSortRow(cs),
                    const SizedBox(height: 16),
                    _buildProductsSection(cs),
                    const SizedBox(height: 24),
                    _buildRfqSection(cs),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wholesale',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              Text('B2B & bulk ordering',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/retro-style-organic-turing-lines-pattern-background-design.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.88),
                    const Color(0xFFB45309).withValues(alpha: 0.55),
                    const Color(0xFFB45309).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warehouse_outlined, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      const Text('Bulk Buying,\nBetter Prices',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Buy in bulk from verified suppliers.\nTiered pricing, MOQ & RFQ available.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildHeroTag('Tiered Pricing'),
                      const SizedBox(width: 8),
                      _buildHeroTag('MOQ'),
                      const SizedBox(width: 8),
                      _buildHeroTag('RFQ'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Text(label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildInfoBanner(ColorScheme cs) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF00A651), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bulk Orders Available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A651),
                ),
              ),
              const SizedBox(height: 2),
              Text('Browse wholesale products below and enjoy tiered pricing!',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTieredPricingCard(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer_outlined, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text('Tiered Pricing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showTieredPricingDrawer(cs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Details',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 12, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: _tiers.map((tier) {
            final color = tier['color'] as Color;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Text(tier['discount'] as String,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(tier['label'] as String,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(tier['range'] as String,
                      style: TextStyle(fontSize: 8, color: cs.onSurface.withValues(alpha: 0.4)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showTieredPricingDrawer(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 24, color: cs.primary),
                  const SizedBox(width: 10),
                  Text('Tiered Pricing',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Buy more, save more. Prices automatically adjust based on quantity.',
                style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _tiers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tier = _tiers[index];
                    final color = tier['color'] as Color;

                    return Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 22, color: color),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tier['label'] as String,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(tier['range'] as String,
                                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        Text(tier['discount'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortRow(ColorScheme cs) {
    return Row(
      children: [
        Text('Wholesale Products',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showSortSheet(cs),
          child: Row(
            children: [
              Icon(Icons.sort, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                _sortBy == 'popular' ? 'Popular' : _sortBy == 'price_low' ? 'Price ↓' : 'Price ↑',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSortSheet(ColorScheme cs) {
    final options = [
      {'value': 'popular', 'label': 'Most Popular', 'icon': Icons.local_fire_department_outlined},
      {'value': 'price_low', 'label': 'Price: Low to High', 'icon': Icons.trending_down},
      {'value': 'price_high', 'label': 'Price: High to Low', 'icon': Icons.trending_up},
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              leading: Icon(opt['icon'] as IconData, size: 18,
                color: _sortBy == opt['value'] ? cs.primary : cs.onSurface.withValues(alpha: 0.5)),
              title: Text(opt['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _sortBy == opt['value'] ? FontWeight.bold : FontWeight.normal,
                  color: _sortBy == opt['value'] ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: _sortBy == opt['value']
                  ? Icon(Icons.check, size: 18, color: cs.primary)
                  : null,
              onTap: () {
                setState(() => _sortBy = opt['value'] as String);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(ColorScheme cs) {
    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadAll(),
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final allProducts = state is ProductsLoaded ? state.products : <ProductModel>[];
          final isLoading = state is ProductsLoading;

          var products = allProducts;
          if (_sortBy == 'price_low') {
            products = List<ProductModel>.from(products)..sort((a, b) => a.price.compareTo(b.price));
          } else if (_sortBy == 'price_high') {
            products = List<ProductModel>.from(products)..sort((a, b) => b.price.compareTo(a.price));
          }

          if (isLoading) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                color: cs.surfaceContainerHighest,
              ),
            );
          }

          if (products.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Text('No products available yet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            );
          }

          final displayProducts = products.take(20).toList();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemCount: displayProducts.length,
            itemBuilder: (context, index) => _buildWholesaleCard(cs, displayProducts[index]),
          );
        },
      ),
    );
  }

  Widget _buildWholesaleCard(ColorScheme cs, ProductModel product) {
    final bulkPrice = product.price * 0.9;

    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute, extra: {
        'product': product,
        'category': product.categoryName ?? 'All',
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.thumbnailUrl != null
                    ? Image.network(
                        product.thumbnailUrl!,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 130,
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          height: 130,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.inventory_2_outlined, size: 28, color: cs.primary.withValues(alpha: 0.3)),
                        ),
                      )
                    : Container(
                        height: 130,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.inventory_2_outlined, size: 28, color: cs.primary.withValues(alpha: 0.3)),
                      ),
              ),
              const Positioned(
                top: 8, left: 8,
                child: Text('WHOLESALE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    Text('MOQ: 10',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(product.formattedPrice,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary),
                ),
                const SizedBox(height: 2),
                Text('Bulk: ${product.currency} ${bulkPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10, color: const Color(0xFF00A651), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRfqSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, size: 22, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Request for Quotation (RFQ)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Can\'t find what you need in bulk? Send a request and suppliers will respond with quotes.',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showRfqForm(cs),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Submit RFQ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showRfqForm(ColorScheme cs) {
    final productCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request for Quotation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text('Fill in your requirements and suppliers will respond',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: productCtrl,
              decoration: const InputDecoration(
                labelText: 'Product name / category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity needed',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional notes (specifications, target price, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('RFQ submitted! Suppliers will respond soon.'),
                    ),
                  );
                },
                child: const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
