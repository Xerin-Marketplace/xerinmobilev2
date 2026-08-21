import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../cubit/products_cubit.dart';
import '../../cubit/products_state.dart';
import '../../../../../core/theme/uicons.dart';

class CustomerExplorePage extends StatefulWidget {
  const CustomerExplorePage({super.key});

  @override
  State<CustomerExplorePage> createState() => _CustomerExplorePageState();
}

class _CustomerExplorePageState extends State<CustomerExplorePage> {
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadAll(),
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final categories = state is ProductsLoaded ? state.categories : <CategoryModel>[];
          final allProducts = state is ProductsLoaded ? state.products : <ProductModel>[];
          final isLoading = state is ProductsLoading;

          final products = _selectedCategoryId != null
              ? allProducts.where((p) => p.categoryId == _selectedCategoryId).toList()
              : allProducts;

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Explore',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                              Text(
                                _selectedCategoryName != null
                                    ? _selectedCategoryName!
                                    : 'All Products',
                                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showFilterSheet(context, colorScheme, categories),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(Uicons.settingsSliders, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategoryId != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedCategoryName = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Uicons.crossSmall, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear filter',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Uicons.box, size: 56, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                                  const SizedBox(height: 12),
                                  Text('No products found', style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.4))),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _buildProductCard(colorScheme, product, isDark);
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ColorScheme colorScheme, List<CategoryModel> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Uicons.settingsSliders, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = null;
                          _selectedCategoryName = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId == null
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : colorScheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategoryId == null
                                ? colorScheme.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Uicons.grid, size: 18,
                              color: _selectedCategoryId == null
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'All Products',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedCategoryId == null ? FontWeight.w700 : FontWeight.w500,
                                  color: _selectedCategoryId == null
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            if (_selectedCategoryId == null)
                              Icon(Uicons.check, size: 18, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    ...categories.map((cat) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat.id;
                          _selectedCategoryName = cat.name;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId == cat.id
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : colorScheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategoryId == cat.id
                                ? colorScheme.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Uicons.category, size: 18,
                              color: _selectedCategoryId == cat.id
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedCategoryId == cat.id ? FontWeight.w700 : FontWeight.w500,
                                  color: _selectedCategoryId == cat.id
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            if (_selectedCategoryId == cat.id)
                              Icon(Uicons.check, size: 18, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ColorScheme colorScheme, ProductModel product, bool isDark) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute, extra: {
        'product': product,
        'category': product.categoryName ?? 'All',
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
                              color: colorScheme.primary.withValues(alpha: 0.06),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => _placeholder(colorScheme),
                        )
                      : _placeholder(colorScheme),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Uicons.heart, size: 16, color: colorScheme.primary),
                  ),
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
                    if ((product.categoryName ?? '').isNotEmpty)
                      Text(
                        product.categoryName!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
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
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
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
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Uicons.shippingFast, size: 11, color: colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text('Xerin Express', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colorScheme.primary.withValues(alpha: 0.5))),
                        const Spacer(),
                        if (product.rating > 0) ...[
                          Icon(Uicons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
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

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      height: 150,
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Uicons.image, color: colorScheme.primary.withValues(alpha: 0.2), size: 36),
      ),
    );
  }
}
