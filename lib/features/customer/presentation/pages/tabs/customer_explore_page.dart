import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../shared/widgets/voice_search_button.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../domain/services/recommendation_engine.dart';
import '../../cubit/products_cubit.dart';
import '../../cubit/products_state.dart';
import '../../cubit/recommendation_cubit.dart';
import '../../cubit/recommendation_state.dart';

class CustomerExplorePage extends StatefulWidget {
  const CustomerExplorePage({super.key});

  @override
  State<CustomerExplorePage> createState() => _CustomerExplorePageState();
}

class _CustomerExplorePageState extends State<CustomerExplorePage> {
  late final ProductsCubit _cubit;
  late final RecommendationCubit _recCubit;
  final _searchCtrl = TextEditingController();
  String? _selectedCategoryId;
  String _searchQuery = '';
  Set<String> _trendingIds = {};
  Set<String> _bestSellerIds = {};
  Set<String> _topRatedIds = {};
  List<ProductModel> _recentlyViewed = [];
  List<StoreModel> _stores = [];
  Map<String, double> _recommendedScores = {};

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductsCubit>()..loadAll();
    _recCubit = sl<RecommendationCubit>()..loadAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Timer? _debounce;
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchCtrl.text.trim();
      setState(() => _searchQuery = query);
      _cubit.loadProducts(
        categoryId: _selectedCategoryId,
        search: query.isEmpty ? null : query,
        limit: 100,
      );
    });
  }

  void _selectCategory(String? id) {
    setState(() => _selectedCategoryId = id);
    _cubit.loadProducts(
      categoryId: id,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      limit: 100,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _cubit.close();
    _recCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.onSurface.withValues(alpha: 0.06)
                      : colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _onSearchChanged();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    if (_searchQuery.isNotEmpty)
                      const SizedBox(width: 4),
                    VoiceSearchButton(
                      colorScheme: colorScheme,
                      size: 18,
                      onResult: (text) {
                        _searchCtrl.text = text;
                        _onSearchChanged();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<RecommendationCubit, RecommendationState>(
          bloc: _recCubit,
          builder: (context, recState) {
            if (recState is RecommendationLoaded) {
              _trendingIds =
                  RecommendationEngine.extractProductIds(recState.trending);
              _bestSellerIds =
                  RecommendationEngine.extractProductIds(recState.bestSellers);
              _topRatedIds =
                  RecommendationEngine.extractProductIds(recState.topRated);
              _recentlyViewed = recState.recentlyViewed;
              _stores = recState.stores;
              _recommendedScores =
                  RecommendationEngine.extractRecommendedScores(
                      recState.recommended);
            }
            return BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
            final categories =
                state is ProductsLoaded ? state.categories : <CategoryModel>[];
            final isLoading = state is ProductsLoading;
            final rawProducts =
                state is ProductsLoaded ? state.products : <ProductModel>[];

            final products = sl<RecommendationEngine>().rank(
              products: rawProducts,
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              trendingIds: _trendingIds,
              bestSellerIds: _bestSellerIds,
              topRatedIds: _topRatedIds,
              recentlyViewed: _recentlyViewed,
              stores: _stores,
              recommendedScores: _recommendedScores,
              selectedCategoryId: _selectedCategoryId,
            );

            return Column(
              children: [
                // Category chips
                if (categories.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final cat = isAll ? null : categories[index - 1];
                        final isSelected = isAll
                            ? _selectedCategoryId == null
                            : _selectedCategoryId == cat?.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(isAll ? 'All' : cat?.name ?? ''),
                            selected: isSelected,
                            onSelected: (_) =>
                                _selectCategory(isAll ? null : cat?.id),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                if (categories.isNotEmpty) const SizedBox(height: 4),

                // Products grid
                Expanded(
                  child: isLoading
                      ? _buildShimmerGrid(colorScheme, isDark)
                      : products.isEmpty
                          ? Center(
                              child: Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(
                                    colorScheme, products[index], isDark);
                              },
                            ),
                ),
              ],
            );
          },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
      ColorScheme colorScheme, ProductModel product, bool isDark) {
    final hasDiscount = product.salePrice != null && product.price > 0;
    final discountPct = hasDiscount
        ? ((1 - (product.salePrice! / product.price)) * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute, extra: {
        'product': product,
        'category': product.categoryName ?? 'All',
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.thumbnailUrl != null
                        ? Image.network(
                            product.thumbnailUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.06),
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
                  if (hasDiscount && discountPct > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '-$discountPct%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (product.rating > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 8, color: Colors.amber),
                            const SizedBox(width: 1),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 8,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          hasDiscount
                              ? '${product.currency} ${product.salePrice!.toStringAsFixed(0)}'
                              : product.formattedPrice,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.primary.withValues(alpha: 0.2),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(ColorScheme colorScheme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return _ShimmerCard(
          colorScheme: colorScheme,
          isDark: isDark,
          delay: Duration(milliseconds: index * 80),
        );
      },
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final ColorScheme colorScheme;
  final bool isDark;
  final Duration delay;

  const _ShimmerCard({
    required this.colorScheme,
    required this.isDark,
    required this.delay,
  });

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? widget.colorScheme.onSurface.withValues(alpha: 0.08)
        : widget.colorScheme.onSurface.withValues(alpha: 0.06);
    final highlightColor = widget.isDark
        ? widget.colorScheme.onSurface.withValues(alpha: 0.14)
        : widget.colorScheme.onSurface.withValues(alpha: 0.10);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _shimmerBox(baseColor, highlightColor,
                      double.infinity, double.infinity),
                ),
              ),
              // Text placeholders
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(baseColor, highlightColor, 80, 10),
                    const SizedBox(height: 5),
                    _shimmerBox(baseColor, highlightColor, 50, 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(
      Color base, Color highlight, double width, double height) {
    final progress = _animation.value;
    // Calculate shimmer position
    final shimmerWidth = width == double.infinity ? 200.0 : width * 0.6;
    final startX = progress * (shimmerWidth * 2) - shimmerWidth;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(startX / shimmerWidth, 0),
          end: Alignment((startX + shimmerWidth) / shimmerWidth, 0),
          colors: [
            base,
            highlight,
            base,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
