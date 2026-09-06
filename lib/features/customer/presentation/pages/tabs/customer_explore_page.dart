import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../cubit/products_cubit.dart';
import '../../cubit/products_state.dart';

class CustomerExplorePage extends StatefulWidget {
  const CustomerExplorePage({super.key});

  @override
  State<CustomerExplorePage> createState() => _CustomerExplorePageState();
}

class _CustomerExplorePageState extends State<CustomerExplorePage> {
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  late final ProductsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductsCubit>()..loadAll();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _selectCategory(String? id, String? name) {
    setState(() {
      _selectedCategoryId = id;
      _selectedCategoryName = name;
    });
    if (id != null) {
      _cubit.loadProducts(categoryId: id, limit: 100);
    } else {
      _cubit.loadProducts(limit: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final categories = state is ProductsLoaded ? state.categories : <CategoryModel>[];
          final isLoading = state is ProductsLoading;

          final products = state is ProductsLoaded ? state.products : <ProductModel>[];

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
                          IconButton(
                            icon: const Icon(Icons.tune, size: 22),
                            onPressed: () => _showFilterSheet(context, colorScheme, categories),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategoryId != null)
                        GestureDetector(
                          onTap: () => _selectCategory(null, null),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Clear filter',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                              ),
                            ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.tune, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(Icons.grid_view_outlined, size: 18,
                        color: _selectedCategoryId == null
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      title: Text(
                        'All Products',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCategoryId == null
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: _selectedCategoryId == null
                          ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        _selectCategory(null, null);
                        Navigator.pop(context);
                      },
                    ),
                    ...categories.map((cat) => ListTile(
                      leading: Icon(Icons.category_outlined, size: 18,
                        color: _selectedCategoryId == cat.id
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedCategoryId == cat.id ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCategoryId == cat.id
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: _selectedCategoryId == cat.id
                          ? Icon(Icons.check, size: 18, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        _selectCategory(cat.id, cat.name);
                        Navigator.pop(context);
                      },
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
                              color: colorScheme.surfaceContainerHighest,
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
                if (product.salePrice != null)
                  Positioned(
                    top: 8, left: 8,
                    child: Text(
                      '-${((1 - product.salePrice! / product.price) * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
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
                        Icon(Icons.local_shipping_outlined, size: 11, color: colorScheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text('Xerin Express', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: colorScheme.primary.withValues(alpha: 0.5))),
                        const Spacer(),
                        if (product.rating > 0) ...[
                          Icon(Icons.star, size: 11, color: Colors.amber),
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
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined, color: colorScheme.primary.withValues(alpha: 0.2), size: 36),
      ),
    );
  }
}
