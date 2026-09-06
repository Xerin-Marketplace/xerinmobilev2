import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../core/theme/app_theme_cubit.dart';
import '../../../../../core/utils/haptic_utils.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';
import '../../cubit/recommendation_cubit.dart';
import '../../cubit/recommendation_state.dart';
import '../../../domain/services/recommendation_engine.dart';
import '../../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../../shared/widgets/voice_search_button.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _searchNode = FocusNode();
  String _searchQuery = '';

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  AnimationController? _aiPulseController;

  @override
  void initState() {
    super.initState();
    _searchNode.addListener(() => setState(() {}));
    _aiPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationCubit>().loadAll();
    });
  }

  @override
  void dispose() {
    _aiPulseController?.dispose();
    _searchCtrl.dispose();
    _searchNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final user = homeState is HomeLoaded ? homeState.user : null;
        final categories = homeState is HomeLoaded
            ? homeState.categories
            : <CategoryModel>[];
        final featured = homeState is HomeLoaded
            ? homeState.featuredProducts
            : <ProductModel>[];
        final searchResults = homeState is HomeLoaded
            ? homeState.searchResults
            : <ProductModel>[];
        final isLoadingData = homeState is HomeLoading;

        if (isLoadingData && homeState is! HomeLoaded) {
          return const SafeArea(child: HomeLoadingSkeleton());
        }

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticUtils.light();
              await context.read<HomeCubit>().loadHome();
              await context.read<RecommendationCubit>().loadAll();
            },
            color: colorScheme.primary,
            strokeWidth: 2.5,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(colorScheme, userName: user?.fullName ?? 'Guest'),
                  const SizedBox(height: 14),
                  _buildSearchBar(colorScheme),
                  const SizedBox(height: 20),
                  if (_searchQuery.isNotEmpty) ...[
                    _buildSearchResults(colorScheme, searchResults, isLoadingData),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildSectionTitle('Categories', 'See all', colorScheme,
                        onActionTap: () => context.push(AppConstants.categoriesRoute)),
                    const SizedBox(height: 14),
                    _buildCategories(colorScheme, categories, isLoadingData),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Recommended For You', 'See all', colorScheme,
                        icon: Icons.auto_awesome_outlined,
                        onActionTap: () => context.push(AppConstants.exploreProductsRoute)),
                    const SizedBox(height: 14),
                    _buildRankedFeaturedProducts(colorScheme, featured, isLoadingData),
                    const SizedBox(height: 28),
                    _buildRecommendationSections(colorScheme),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, {required String userName}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: const AssetImage('assets/images/avatar.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push(AppConstants.xerinAiRoute),
              child: _aiPulseController != null
                  ? AnimatedBuilder(
                      animation: _aiPulseController!,
                      builder: (context, child) {
                        final scale =
                            1.0 + _aiPulseController!.value * 0.12;
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/icons/uicons-thin-rounded/ai.png',
                        width: 24,
                        height: 24,
                      ),
                    )
                  : Image.asset(
                      'assets/icons/uicons-thin-rounded/ai.png',
                      width: 24,
                      height: 24,
                    ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => sl<AppThemeCubit>().toggleTheme(),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchNode.hasFocus
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.08),
          width: _searchNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search,
            color: _searchNode.hasFocus
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.35),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchNode,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              onChanged: (v) {
                final q = v.trim();
                setState(() => _searchQuery = q.toLowerCase());
                context.read<HomeCubit>().searchProducts(q);
              },
              decoration: InputDecoration(
                hintText: 'What are you looking for?',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ),
            ),
          if (_searchQuery.isNotEmpty)
            const SizedBox(width: 4),
          VoiceSearchButton(
            colorScheme: colorScheme,
            onResult: (text) {
              _searchCtrl.text = text;
              setState(() => _searchQuery = text.toLowerCase());
              context.read<HomeCubit>().searchProducts(text);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    ColorScheme colorScheme,
    List<ProductModel> results,
    bool isLoading,
  ) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'No products found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${results.length} found',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          children: results.map((product) {
            return GestureDetector(
              onTap: () => context.push(
                AppConstants.productDetailRoute,
                extra: {
                  'product': product,
                  'category': product.categoryName ?? 'All',
                },
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: product.thumbnailUrl != null
                          ? Image.network(
                              product.thumbnailUrl!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _productPlaceholder(colorScheme, product.categoryName),
                            )
                          : _productPlaceholder(colorScheme, product.categoryName),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.categoryName ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
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

  Widget _productPlaceholder(ColorScheme colorScheme, String? category) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          (category ?? '?')[0].toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(
    String title,
    String action,
    ColorScheme colorScheme, {
    VoidCallback? onActionTap,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: colorScheme.primary, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(
    ColorScheme colorScheme,
    List<CategoryModel> categories,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => Container(
            width: 90,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox(
        height: 44,
        child: Center(child: Text('No categories', style: TextStyle(fontSize: 13))),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => context.push(
              AppConstants.categoryProductsRoute,
              extra: {'category': cat.name, 'categoryId': cat.id},
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.onSurface.withValues(alpha: 0.08)
                    : colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  cat.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.85)
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankedFeaturedProducts(
    ColorScheme colorScheme,
    List<ProductModel> products,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: 4,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No products yet', style: TextStyle(fontSize: 13))),
      );
    }

    // Apply ranking engine with signals from RecommendationCubit
    final recState = context.read<RecommendationCubit>().state;
    Set<String> trendingIds = {};
    Set<String> bestSellerIds = {};
    Set<String> topRatedIds = {};
    List<ProductModel> recentlyViewed = [];
    List<StoreModel> stores = [];
    Map<String, double> recommendedScores = {};

    if (recState is RecommendationLoaded) {
      trendingIds = RecommendationEngine.extractProductIds(recState.trending);
      bestSellerIds = RecommendationEngine.extractProductIds(recState.bestSellers);
      topRatedIds = RecommendationEngine.extractProductIds(recState.topRated);
      recentlyViewed = recState.recentlyViewed;
      stores = recState.stores;
      recommendedScores =
          RecommendationEngine.extractRecommendedScores(recState.recommended);
    }

    final ranked = sl<RecommendationEngine>().rank(
      products: products,
      trendingIds: trendingIds,
      bestSellerIds: bestSellerIds,
      topRatedIds: topRatedIds,
      recentlyViewed: recentlyViewed,
      stores: stores,
      recommendedScores: recommendedScores,
      maxPerSeller: 1,
      diversifyTopN: 4,
    );

    final top4 = ranked.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: top4.length,
      itemBuilder: (context, index) {
        return _buildProductCard(colorScheme, top4[index], isDark);
      },
    );
  }

  Widget _buildProductCard(
    ColorScheme colorScheme,
    ProductModel product,
    bool isDark,
  ) {
    final hasDiscount = product.salePrice != null && product.price > 0;
    final discountPct = hasDiscount
        ? ((1 - (product.salePrice! / product.price)) * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: () => context.push(
        AppConstants.productDetailRoute,
        extra: {
          'product': product,
          'category': product.categoryName ?? 'All',
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: product.thumbnailUrl != null
                        ? Image.network(
                            product.thumbnailUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: colorScheme.primary.withValues(alpha: 0.06),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => _featuredPlaceholder(colorScheme, product.categoryName),
                          )
                        : _featuredPlaceholder(colorScheme, product.categoryName),
                  ),
                  // Discount badge
                  if (hasDiscount && discountPct > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discountPct%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Rating badge
                  if (product.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != null)
                    Text(
                      product.categoryName!,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          hasDiscount
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredPlaceholder(ColorScheme colorScheme, String? category) {
    return Container(
      height: 145,
      width: 168,
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Center(
        child: Text(
          (category ?? 'Product')[0].toUpperCase(),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationSections(ColorScheme colorScheme) {
    return BlocBuilder<RecommendationCubit, RecommendationState>(
      builder: (context, state) {
        if (state is! RecommendationLoaded) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Recommended For You — personalized from backend
            if (state.recommended.isNotEmpty) ...[
              _buildSectionTitle(
                'For You',
                'See all',
                colorScheme,
                icon: Icons.auto_awesome_outlined,
                onActionTap: () => context.push(AppConstants.forYouRoute),
              ),
              const SizedBox(height: 14),
              _buildRecommendedCarousel(colorScheme, state.recommended),
              const SizedBox(height: 28),
            ],
            // 2. Trending Now
            if (state.trending.isNotEmpty) ...[
              _buildSectionTitle(
                'Trending Now',
                'See all',
                colorScheme,
                icon: Icons.local_fire_department_outlined,
                onActionTap: () => context.push(AppConstants.trendingRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme,
                sl<RecommendationEngine>().rank(
                  products: state.trending,
                  trendingIds: RecommendationEngine.extractProductIds(state.trending),
                  bestSellerIds: RecommendationEngine.extractProductIds(state.bestSellers),
                  stores: state.stores,
                  maxPerSeller: 2,
                  diversifyTopN: 10,
                ),
              ),
              const SizedBox(height: 28),
            ],
            // 3. Popular Near You — using topRated as proxy
            if (state.topRated.isNotEmpty) ...[
              _buildSectionTitle(
                'Popular Near You',
                'See all',
                colorScheme,
                icon: Icons.near_me_outlined,
                onActionTap: () => context.push(AppConstants.exploreProductsRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme,
                sl<RecommendationEngine>().rank(
                  products: state.topRated,
                  topRatedIds: RecommendationEngine.extractProductIds(state.topRated),
                  stores: state.stores,
                  maxPerSeller: 2,
                  diversifyTopN: 10,
                ),
              ),
              const SizedBox(height: 28),
            ],
            // 4. Based On Your Recent Views
            if (state.recentlyViewed.isNotEmpty) ...[
              _buildSectionTitle(
                'Based On Your Recent Views',
                'See all',
                colorScheme,
                icon: Icons.history_outlined,
                onActionTap: () => context.push(AppConstants.recentlyViewedRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.recentlyViewed),
              const SizedBox(height: 28),
            ],
            // 5. Best Sellers
            if (state.bestSellers.isNotEmpty) ...[
              _buildSectionTitle(
                'Best Sellers',
                'See all',
                colorScheme,
                icon: Icons.trending_up_outlined,
                onActionTap: () => context.push(AppConstants.exploreProductsRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme,
                sl<RecommendationEngine>().rank(
                  products: state.bestSellers,
                  bestSellerIds: RecommendationEngine.extractProductIds(state.bestSellers),
                  stores: state.stores,
                  maxPerSeller: 2,
                  diversifyTopN: 10,
                ),
              ),
              const SizedBox(height: 28),
            ],
            // 6. New Arrivals
            if (state.newArrivals.isNotEmpty) ...[
              _buildSectionTitle(
                'New Arrivals',
                'See all',
                colorScheme,
                icon: Icons.new_releases_outlined,
                onActionTap: () => context.push(AppConstants.newArrivalsRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme,
                sl<RecommendationEngine>().rank(
                  products: state.newArrivals,
                  stores: state.stores,
                  maxPerSeller: 2,
                  diversifyTopN: 10,
                ),
              ),
              const SizedBox(height: 28),
            ],
            // 7. Deals
            if (state.flashDeals.isNotEmpty) ...[
              _buildSectionTitle(
                'Deals',
                'See all',
                colorScheme,
                icon: Icons.local_offer_outlined,
                onActionTap: () => context.push(AppConstants.flashDealsRoute),
              ),
              const SizedBox(height: 14),
              _buildFlashDealsCarousel(colorScheme, state.flashDeals),
              const SizedBox(height: 28),
            ],
            // Top Stores
            if (state.stores.isNotEmpty) ...[
              _buildSectionTitle(
                'Top Stores',
                'See all',
                colorScheme,
                icon: Icons.store_outlined,
                onActionTap: () => context.push(AppConstants.storesRoute),
              ),
              const SizedBox(height: 14),
              _buildStoresCarousel(colorScheme, state.stores),
              const SizedBox(height: 28),
            ],
            // Available Coupons
            if (state.coupons.isNotEmpty) ...[
              _buildSectionTitle(
                'Available Coupons',
                'See all',
                colorScheme,
                icon: Icons.confirmation_number_outlined,
                onActionTap: () => context.push(AppConstants.couponsRoute),
              ),
              const SizedBox(height: 14),
              _buildCouponsCarousel(colorScheme, state.coupons),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFlashDealsCarousel(
      ColorScheme cs, List<FlashDealModel> deals) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: deals.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final deal = deals[index];
          final product = deal.product;
          return SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => context.push(AppConstants.productDetailRoute,
                  extra: {'product': product, 'category': product.categoryName ?? 'All'}),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: product.thumbnailUrl != null
                                ? Image.network(product.thumbnailUrl!,
                                    width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _carouselPlaceholder(cs, product.categoryName))
                                : _carouselPlaceholder(cs, product.categoryName),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                '-${deal.discountPercentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(deal.formattedDealPrice,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCarousel(
      ColorScheme cs, List<RecommendedProductModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final product = item.product;
          return SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => context.push(AppConstants.productDetailRoute,
                  extra: {'product': product, 'category': product.categoryName ?? 'All'}),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: product.thumbnailUrl != null
                            ? Image.network(product.thumbnailUrl!,
                                width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _carouselPlaceholder(cs, product.categoryName))
                            : _carouselPlaceholder(cs, product.categoryName),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_outlined, size: 10, color: cs.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(item.reason,
                                    style: TextStyle(fontSize: 10, color: cs.primary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(product.formattedPrice,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCarousel(ColorScheme cs, List<ProductModel> products) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 140,
            child: GestureDetector(
              onTap: () => context.push(AppConstants.productDetailRoute,
                  extra: {'product': product, 'category': product.categoryName ?? 'All'}),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: product.thumbnailUrl != null
                            ? Image.network(product.thumbnailUrl!,
                                width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _carouselPlaceholder(cs, product.categoryName))
                            : _carouselPlaceholder(cs, product.categoryName),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(product.formattedPrice,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _carouselPlaceholder(ColorScheme cs, String? category) {
    return Container(
      color: cs.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, size: 28, color: cs.primary.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildStoresCarousel(ColorScheme cs, List<StoreModel> stores) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return GestureDetector(
            onTap: () => context.push(AppConstants.storesRoute),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: store.logoUrl != null
                        ? ClipOval(
                            child: Image.network(store.logoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.store_outlined, color: cs.primary)),
                          )
                        : Icon(Icons.store_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(store.name,
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (store.isVerified)
                              Icon(Icons.verified, size: 14, color: cs.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (store.rating > 0) ...[
                              Icon(Icons.star, size: 12, color: Colors.amber[600]),
                              const SizedBox(width: 2),
                              Text(store.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                            ],
                            const SizedBox(width: 8),
                            Text('${store.totalProducts} items',
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponsCarousel(ColorScheme cs, List<CouponModel> coupons) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary.withValues(alpha: 0.08), cs.primary.withValues(alpha: 0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: cs.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(coupon.code,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
                      const SizedBox(height: 2),
                      Text(coupon.discountDisplay,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
