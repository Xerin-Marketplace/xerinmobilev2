import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
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
                    child: Icon(Icons.arrow_back, size: 22, color: colorScheme.onSurface),
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
                    icon: const Icon(Icons.refresh, size: 20),
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
                      child: Text('No products in this category yet',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.5))),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                        fontWeight: FontWeight.w600,
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
                    if (product.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ],
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
        child: Icon(Icons.image_outlined, color: cs.primary.withValues(alpha: 0.2), size: 36),
      ),
    );
  }
}
