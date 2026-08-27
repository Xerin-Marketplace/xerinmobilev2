import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/product_model.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

class CategoryProductsPage extends StatefulWidget {
  final String category;
  final String? categoryId;

  const CategoryProductsPage({
    super.key,
    required this.category,
    this.categoryId,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late final ProductsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductsCubit>();
    _loadProducts();
  }

  void _loadProducts() {
    if (widget.categoryId != null) {
      _cubit.loadProducts(categoryId: widget.categoryId, limit: 100);
    } else {
      _cubit.loadProducts(limit: 100);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppConstants.categoriesRoute);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Uicons.arrowBack,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        BlocBuilder<ProductsCubit, ProductsState>(
                          bloc: _cubit,
                          builder: (context, state) {
                            final count = state is ProductsLoaded
                                ? state.products.length
                                : 0;
                            return Text(
                              '$count products',
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
                  IconButton(
                    icon: const Icon(Uicons.refresh, size: 20),
                    onPressed: _loadProducts,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProductsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Uicons.circleExclamation, size: 48,
                              color: colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text(state.message,
                              style: TextStyle(fontSize: 14,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final products = state is ProductsLoaded ? state.products : <ProductModel>[];
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Uicons.box, size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('No products in this category yet',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(colorScheme, isDark, products[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ColorScheme cs, bool isDark, ProductModel product) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute, extra: {
        'product': product,
        'category': product.categoryName ?? widget.category,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: product.thumbnailUrl != null
                      ? Image.network(
                          product.thumbnailUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 150,
                              color: cs.primary.withValues(alpha: 0.06),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => _placeholder(cs),
                        )
                      : _placeholder(cs),
                ),
                if (product.salePrice != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${((1 - product.salePrice! / product.price) * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (product.salePrice != null) ...[
                          Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.4),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            product.salePrice != null
                                ? '${product.currency} ${product.salePrice!.toStringAsFixed(0)}'
                                : product.formattedPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Uicons.shippingFast, size: 11, color: cs.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text('Xerin Express', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cs.primary.withValues(alpha: 0.5))),
                        const Spacer(),
                        if (product.rating > 0) ...[
                          Icon(Uicons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      height: 150,
      color: cs.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Uicons.image, color: cs.primary.withValues(alpha: 0.2), size: 36),
      ),
    );
  }
}
