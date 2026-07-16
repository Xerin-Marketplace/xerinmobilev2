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
  final _searchCtrl = TextEditingController();

  static IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('electron') || n.contains('gadget')) return Icons.devices_rounded;
    if (n.contains('fashion') || n.contains('cloth') || n.contains('wear')) return Icons.checkroom_rounded;
    if (n.contains('home') || n.contains('furniture')) return Icons.home_rounded;
    if (n.contains('auto') || n.contains('car')) return Icons.directions_car_rounded;
    if (n.contains('sport') || n.contains('fitness')) return Icons.sports_soccer_rounded;
    if (n.contains('book') || n.contains('media')) return Icons.book_rounded;
    if (n.contains('health') || n.contains('beauty')) return Icons.health_and_safety_rounded;
    if (n.contains('food') || n.contains('drink')) return Icons.restaurant_rounded;
    if (n.contains('phone') || n.contains('mobile')) return Icons.phone_android_rounded;
    if (n.contains('computer') || n.contains('laptop')) return Icons.laptop_rounded;
    return Icons.category_rounded;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..loadAll(),
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          final categories = state is ProductsLoaded ? state.categories : <CategoryModel>[];
          final products = state is ProductsLoaded ? state.products : <ProductModel>[];
          final trending = state is ProductsLoaded ? state.trending : <ProductModel>[];
          final flashSaleProducts = products.where((p) => p.salePrice != null).take(5).toList();
          final isLoading = state is ProductsLoading;

          return SafeArea(
            child: SingleChildScrollView(
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
                          Text('Discover amazing deals',
                            style: TextStyle(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.45)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _iconBtn(Icons.notifications_outlined, colorScheme, () => context.push(AppConstants.notificationsRoute)),
                          const SizedBox(width: 8),
                          _iconBtn(Icons.favorite_outline_rounded, colorScheme, () {}),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(colorScheme, context),
                  const SizedBox(height: 24),
                  _buildFlashSale(colorScheme, flashSaleProducts, isLoading, context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Categories', colorScheme),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(colorScheme, categories, isLoading, context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Trending Now', colorScheme),
                  const SizedBox(height: 16),
                  _buildTrendingList(colorScheme, trending, isLoading, context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('All Products', colorScheme),
                  const SizedBox(height: 16),
                  _buildProductGrid(colorScheme, products, isLoading, context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _iconBtn(IconData icon, ColorScheme cs, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: cs.onSurface.withValues(alpha: 0.7), size: 22),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: colorScheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  context.read<ProductsCubit>().loadProducts(search: v.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Search products, brands...',
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () => _searchCtrl.clear(),
              child: Icon(Icons.close_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFlashSale(
    ColorScheme colorScheme,
    List<ProductModel> products,
    bool isLoading,
    BuildContext context,
  ) {
    if (isLoading) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(Icons.flash_off_rounded, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('Flash Sale not available',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text('Check back later for hot deals',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: const Color(0xFFF59E0B), size: 22),
                const SizedBox(width: 8),
                Text('Flash Sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ],
            ),
            Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              final discount = product.salePrice != null
                  ? ((1 - product.salePrice! / product.price) * 100).toInt()
                  : 0;
              return GestureDetector(
                onTap: () => context.push(AppConstants.productDetailRoute, extra: {
                  'product': product,
                  'category': product.categoryName ?? 'All',
                }),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 90, height: 90,
                          color: Colors.white.withValues(alpha: 0.2),
                          child: product.thumbnailUrl != null
                              ? Image.network(product.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _productPlaceholder(colorScheme))
                              : _productPlaceholder(colorScheme),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(product.name,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (product.salePrice != null) ...[
                              Text(product.formattedPrice,
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), decoration: TextDecoration.lineThrough),
                              ),
                              Text('${product.currency} ${product.salePrice!.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(6)),
                                child: Text('-$discount%',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorScheme.primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.primary)),
      ],
    );
  }

  Widget _buildCategoryGrid(ColorScheme colorScheme, List<CategoryModel> categories, bool isLoading, BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final displayCats = categories.take(8).toList();
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: displayCats.length,
      itemBuilder: (context, index) {
        final cat = displayCats[index];
        return GestureDetector(
          onTap: () => context.push(AppConstants.categoryProductsRoute, extra: {'category': cat.name, 'categoryId': cat.id}),
          child: Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(_categoryIcon(cat.name), color: colorScheme.primary, size: 26),
              ),
              const SizedBox(height: 8),
              Text(cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingList(ColorScheme colorScheme, List<ProductModel> trending, bool isLoading, BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    final items = trending.take(4).toList();
    if (items.isEmpty) {
      return Container(padding: const EdgeInsets.all(20),
        child: Center(child: Text('No trending products', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)))),
      );
    }
    return Column(
      children: items.map((product) {
        return GestureDetector(
          onTap: () => context.push(AppConstants.productDetailRoute, extra: {
            'name': product.name, 'price': product.formattedPrice, 'image': product.thumbnailUrl ?? '',
            'category': product.categoryName ?? '', 'rating': product.rating,
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: product.thumbnailUrl != null
                      ? Image.network(product.thumbnailUrl!, width: 52, height: 52, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _productPlaceholder(colorScheme))
                      : _productPlaceholder(colorScheme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_rounded, size: 14, color: const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text('Hot', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                    ]),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(product.formattedPrice, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  if (product.salePrice != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFE53935).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('-${((1 - product.salePrice! / product.price) * 100).toInt()}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFE53935))),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _productPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary.withValues(alpha: 0.4), size: 24),
    );
  }

  Widget _buildProductGrid(ColorScheme colorScheme, List<ProductModel> products, bool isLoading, BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (products.isEmpty) {
      return Container(padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('No products available', style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.4))),
          ]),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => context.push(AppConstants.productDetailRoute, extra: {
            'name': product.name, 'price': product.formattedPrice, 'image': product.thumbnailUrl ?? '',
            'category': product.categoryName ?? '', 'rating': product.rating,
          }),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
              boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(fit: StackFit.expand, children: [
                    product.thumbnailUrl != null
                        ? Image.network(product.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _productGridPlaceholder(colorScheme))
                        : _productGridPlaceholder(colorScheme),
                    Positioned(top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: Icon(Icons.favorite_outline_rounded, size: 16, color: colorScheme.primary),
                      ),
                    ),
                    if (product.salePrice != null)
                      Positioned(top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(8)),
                          child: Text('SALE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(product.formattedPrice, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  if (product.salePrice != null) ...[
                    const SizedBox(height: 2),
                    Text(product.formattedPrice, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4), decoration: TextDecoration.lineThrough)),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                  ]),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _productGridPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Icon(Icons.image_outlined, color: colorScheme.primary.withValues(alpha: 0.2), size: 40),
    );
  }
}
