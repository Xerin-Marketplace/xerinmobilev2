import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

class ExploreProductsPage extends StatefulWidget {
  const ExploreProductsPage({super.key});

  @override
  State<ExploreProductsPage> createState() => _ExploreProductsPageState();
}

class _ExploreProductsPageState extends State<ExploreProductsPage> {
  late final ProductsCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  String _marketFilter = 'all';

  static const _marketOptions = [
    {'key': 'all', 'label': 'All Products', 'icon': Icons.public, 'color': Color(0xFF6C5CE7)},
    {'key': 'local', 'label': 'Local · Tanzania', 'icon': Icons.store_outlined, 'color': Color(0xFF3B82F6)},
    {'key': 'global', 'label': 'Global', 'icon': Icons.language, 'color': Color(0xFF00A651)},
  ];

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductsCubit>()..loadAll();
  }

  @override
  void dispose() {
    _cubit.close();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _applyMarketFilter(List<ProductModel> products) {
    switch (_marketFilter) {
      case 'local':
        return products.where((p) {
          final c = (p.country ?? '').toLowerCase();
          return c.isEmpty || c.contains('tanzania') || c.contains('tz');
        }).toList();
      case 'global':
        return products.where((p) {
          final c = (p.country ?? '').toLowerCase();
          return c.isNotEmpty && !c.contains('tanzania') && !c.contains('tz');
        }).toList();
      default:
        return products;
    }
  }

  String _categoryName(List<CategoryModel> categories, String categoryId) {
    final match = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => const CategoryModel(id: '', name: 'General', slug: 'general'),
    );
    return match.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocProvider.value(
        value: _cubit,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppConstants.homeRoute);
                          }
                        },
                        child: Icon(Icons.arrow_back, size: 22, color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore Products',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            BlocBuilder<ProductsCubit, ProductsState>(
                              builder: (context, state) {
                                final count = state is ProductsLoaded ? state.products.length : 0;
                                return Text(
                                  '$count products available',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) => _cubit.loadProducts(search: value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _cubit.loadAll();
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              // Market filter dropdown
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _buildMarketFilterDropdown(colorScheme),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: BlocBuilder<ProductsCubit, ProductsState>(
                  builder: (context, state) {
                    if (state is ProductsLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is ProductsError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final loaded = state is ProductsLoaded ? state : const ProductsLoaded();
                    final allProducts = loaded.products;
                    final categories = loaded.categories;
                    final products = _applyMarketFilter(allProducts);
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text('No products found', style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.4))),
                        ),
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return _buildProductCard(
                            product,
                            _categoryName(categories, product.categoryId),
                            colorScheme,
                            context,
                          );
                        },
                        childCount: products.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketFilterDropdown(ColorScheme cs) {
    final selected = _marketOptions.where((m) => m['key'] == _marketFilter).firstOrNull;
    final selectedLabel = selected?['label'] as String ?? 'All Products';
    final selectedIcon = selected?['icon'] as IconData ?? Icons.public;
    final selectedColor = selected?['color'] as Color ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08), width: 1),
      ),
      child: PopupMenuButton<String>(
        onSelected: (key) {
          setState(() => _marketFilter = key);
        },
        offset: const Offset(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(selectedIcon, size: 18, color: selectedColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
        itemBuilder: (context) => _marketOptions.map((m) {
          final key = m['key'] as String;
          final label = m['label'] as String;
          final icon = m['icon'] as IconData;
          final color = m['color'] as Color;
          final isSelected = _marketFilter == key;

          return PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: cs.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(
      ProductModel product, String category, ColorScheme colorScheme, BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(
        AppConstants.productDetailRoute,
        extra: {
          'product': product,
          'category': category,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: product.thumbnailUrl != null
                    ? Image.network(
                        product.thumbnailUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (product.rating > 0) ...[
                        Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
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
}
