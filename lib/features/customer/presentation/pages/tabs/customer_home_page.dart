import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../../../core/theme/country_data.dart';
import '../../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../../../shared/widgets/voice_search_button.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _searchCtrl = TextEditingController();
  final _searchNode = FocusNode();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedRegion;
  String? _selectedPriceRange;

  final _heroController = PageController();
  int _currentHeroPage = 0;
  Timer? _heroTimer;

  String _selectedMarket = 'all';
  List<ProductModel> _marketProducts = [];
  bool _isLoadingMarket = false;

  static const _heroSlides = [
    {
      'image': 'assets/images/ecommerce-phone-happy-black-woman-with-credit-card-online-shopping-digital-payment-app-home-smile-banking-excited-african-girl-checks-cash-budget-money-growth-savings-online_590464-111903.jpg',
      'title': 'Shop Smart, Pay Easy',
      'subtitle': 'Secure payments and great deals at your fingertips',
    },
    {
      'image': 'assets/images/elegant-attractive-muslim-woman-using-mobile-laptop-searching-online-shopping-information-living-room-home-portrait-happy-woman-purchasing-product-via-online-shopping-pay-using-credit-card_657921-979.jpg',
      'title': 'Your Store, Delivered',
      'subtitle': 'Browse thousands of products from the comfort of home',
    },
  ];

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  void initState() {
    super.initState();
    _searchNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationCubit>().loadAll();
    });
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroController.hasClients) return;
      final next = (_currentHeroPage + 1) % _heroSlides.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchNode.dispose();
    _heroTimer?.cancel();
    _heroController.dispose();
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

        if (homeState is HomeLoaded && _marketProducts.isEmpty && !_isLoadingMarket) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadMarketProducts('all');
          });
        }

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
                  _buildPromoBanner(colorScheme),
                  const SizedBox(height: 14),
                  _buildSearchBar(colorScheme),
                  const SizedBox(height: 20),
                  if (_searchQuery.isNotEmpty) ...[
                    _buildSearchResults(colorScheme, searchResults, isLoadingData),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Categories
                    _buildSectionTitle(
                      'Explore Categories',
                      'See all',
                      colorScheme,
                      onActionTap: () {
                        HapticUtils.selection();
                        context.push(AppConstants.categoriesRoute);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildCategories(colorScheme, categories, isLoadingData),
                    const SizedBox(height: 28),

                    // Flash Sale banner — early placement for visibility
                    _buildFlashSaleBanner(colorScheme),
                    const SizedBox(height: 28),

                    // Featured products
                    _buildSectionTitle(
                      'Featured',
                      'See all',
                      colorScheme,
                      icon: Icons.star_outline,
                      onActionTap: () {
                        HapticUtils.selection();
                        context.push(AppConstants.exploreProductsRoute);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildFeaturedProducts(colorScheme, featured, isLoadingData),
                    const SizedBox(height: 28),

                    // Interleaved recommendation sections — mixed with other content
                    _buildRecommendationSections(colorScheme),
                    const SizedBox(height: 24),

                    // Discover Mix — after recommendations for variety
                    _buildDiscoverMix(colorScheme, featured),
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
        GestureDetector(
          onTap: () => sl<AppThemeCubit>().toggleTheme(),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: colorScheme.onSurface.withValues(alpha: 0.75),
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _iconBadge(
    IconData icon, {
    required String badge,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    final hasBadge = badge.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                size: 22,
              ),
            ),
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsPopup(BuildContext context, ColorScheme colorScheme) {
    final notifications = [
      {'title': 'Order shipped', 'body': 'Your order XM-260811-00125 is on the way', 'time': '2m ago'},
      {'title': 'Flash Sale!', 'body': 'Get 50% off on electronics today', 'time': '1h ago'},
      {'title': 'New arrival', 'body': 'New running shoes are now available', 'time': '3h ago'},
      {'title': 'Order delivered', 'body': 'Your order XM-260810-00098 was delivered', 'time': '5h ago'},
    ];
    _showIconPopup(
      context: context,
      colorScheme: colorScheme,
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      items: notifications,
      itemBuilder: (notification) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 20),
        title: Text(
          notification['title']!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${notification['body']} • ${notification['time']}',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showWishlistPopup(BuildContext context, ColorScheme colorScheme) {
    final items = [
      {'name': 'Wireless Headphones', 'price': '\$129.99'},
      {'name': 'Smart Watch Series 5', 'price': '\$249.00'},
      {'name': 'Running Shoes Pro', 'price': '\$89.50'},
      {'name': 'Laptop Stand', 'price': '\$45.99'},
    ];
    _showIconPopup(
      context: context,
      colorScheme: colorScheme,
      title: 'Wishlist',
      icon: Icons.favorite_outline,
      items: items,
      itemBuilder: (item) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.favorite_outline, color: Color(0xFFE53935), size: 20),
        title: Text(
          item['name']!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        trailing: Text(
          item['price']!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  void _showIconPopup<T>({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required List<T> items,
    required Widget Function(T) itemBuilder,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              margin: const EdgeInsets.only(left: 0),
              padding: const EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: itemBuilder(item),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildPromoBanner(ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _heroController,
            itemCount: _heroSlides.length,
            onPageChanged: (i) => setState(() => _currentHeroPage = i),
            itemBuilder: (context, index) {
              final slide = _heroSlides[index];
              return _buildHeroCard(
                colorScheme,
                image: slide['image']!,
                title: slide['title']!,
                subtitle: slide['subtitle']!,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroSlides.length, (i) {
            final active = i == _currentHeroPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 18 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    ColorScheme colorScheme, {
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  void _showFilterSheet(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = context.read<HomeCubit>().state;
    final categoryNames = homeState is HomeLoaded
        ? homeState.categories.map((c) => c.name).toList()
        : <String>[];
    final priceRanges = const [
      'All',
      '0 - 100k',
      '100k - 250k',
      '250k - 500k',
      '500k+',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.tune,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterSection(
                                'Category',
                                categoryNames,
                                _selectedCategory,
                                (value) => setModalState(() {
                                  _selectedCategory =
                                      _selectedCategory == value ? null : value;
                                }),
                                colorScheme,
                              ),
                              const SizedBox(height: 20),
                              _buildFilterSection(
                                'Region / Location',
                                const ['Dar es Salaam', 'Arusha', 'Mwanza', 'Kilimanjaro', 'Dodoma', 'Zanzibar'],
                                _selectedRegion,
                                (value) => setModalState(() {
                                  _selectedRegion =
                                      _selectedRegion == value ? null : value;
                                }),
                                colorScheme,
                              ),
                              const SizedBox(height: 20),
                              _buildFilterSection(
                                'Price Range (TZS)',
                                priceRanges,
                                _selectedPriceRange,
                                (value) => setModalState(() {
                                  _selectedPriceRange =
                                      _selectedPriceRange == value ? null : value;
                                }),
                                colorScheme,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedCategory = null;
                                    _selectedRegion = null;
                                    _selectedPriceRange = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.onSurface.withValues(alpha: 0.15),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(modalContext);
                                  final q = _searchCtrl.text.trim();
                                  setState(() => _searchQuery = q.toLowerCase());
                                  context.read<HomeCubit>().searchProducts(q);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                  shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selectedValue,
    ValueChanged<String> onSelected,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title.contains('Category') ? Icons.category_outlined
                  : title.contains('Region') ? Icons.location_on_outlined
                  : Icons.attach_money,
                color: Colors.white, size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  Widget _buildBecomeSellerCard(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> _openWhatsApp() async {
      final phoneNumber = '255222000000';
      final message = Uri.encodeComponent(
          'Hello XerinMarket! I am interested in becoming a seller on your platform. Please share more details.');
      final url = Uri.parse('https://wa.me/$phoneNumber?text=$message');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.3 : 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/retro-style-organic-turing-lines-pattern-background-design.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 280,
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1B1B3A).withValues(alpha: 0.85), const Color(0xFF2D1B4E).withValues(alpha: 0.9)]
                        : [const Color(0xFF6C5CE7).withValues(alpha: 0.82), const Color(0xFF8B5CF6).withValues(alpha: 0.88)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.store_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Become a Seller',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Start selling on XerinMarket today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _sellerBenefit(Icons.trending_up, 'Reach thousands of buyers'),
                    const SizedBox(width: 12),
                    _sellerBenefit(Icons.account_balance_wallet_outlined, 'Easy payouts & low fees'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _sellerBenefit(Icons.inventory_2_outlined, 'Manage orders easily'),
                    const SizedBox(width: 12),
                    _sellerBenefit(Icons.star_outline, 'Grow your brand'),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25D366)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Contact us on WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _sellerBenefit(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static const _mainMarkets = [
    {'key': 'all', 'label': 'All Products', 'subtitle': 'Local and global stores', 'icon': Icons.public, 'color': Color(0xFF6C5CE7)},
    {'key': 'local', 'label': 'Local · Tanzania', 'subtitle': 'Products registered in Tanzania', 'icon': Icons.store_outlined, 'color': Color(0xFF3B82F6)},
    {'key': 'global', 'label': 'Global', 'subtitle': 'All countries outside Tanzania', 'icon': Icons.public, 'color': Color(0xFF00A651)},
  ];

  String? _selectedCountry;

  void _loadMarketProducts(String marketKey) {
    setState(() {
      _selectedMarket = marketKey;
      _isLoadingMarket = true;
    });

    final homeState = context.read<HomeCubit>().state;
    final allProducts = homeState is HomeLoaded ? homeState.featuredProducts : <ProductModel>[];

    List<ProductModel> filtered;
    switch (marketKey) {
      case 'all':
        filtered = allProducts;
        break;
      case 'local':
      case 'tanzania':
        filtered = allProducts.where((p) {
          final c = (p.country ?? '').toLowerCase();
          return c.isEmpty || c.contains('tanzania') || c.contains('tz');
        }).toList();
        break;
      case 'global':
        filtered = allProducts.where((p) {
          final c = (p.country ?? '').toLowerCase();
          return c.isNotEmpty && !c.contains('tanzania') && !c.contains('tz');
        }).toList();
        break;
      default:
        // Dynamic country filtering — marketKey is the country name from backend
        final countryLower = marketKey.toLowerCase();
        filtered = allProducts.where((p) {
          final c = (p.country ?? '').toLowerCase();
          return c.contains(countryLower) ||
              countryLower.contains(c) ||
              _matchesCountryCode(c, countryLower);
        }).toList();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _marketProducts = filtered;
          _isLoadingMarket = false;
        });
      }
    });
  }

  bool _matchesCountryCode(String productCountry, String marketKey) {
    final countryData = CountryData.countries.where(
      (c) => c.name.toLowerCase() == marketKey.toLowerCase(),
    ).firstOrNull;
    if (countryData == null) return false;
    return productCountry.contains(countryData.isoCode.toLowerCase());
  }

  Widget _buildMarketplaceSections(ColorScheme cs, List<ProductModel> featured, bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.public, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop by Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Products from local and global stores',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(AppConstants.exploreProductsRoute),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: cs.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter dropdown — All, Local, Global
        _buildMarketFilterDropdown(cs, isDark, featured),
        const SizedBox(height: 16),

        // Products grid
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isLoadingMarket
              ? _buildMarketLoadingGrid(cs, isDark)
              : _marketProducts.isEmpty
                  ? _buildMarketEmptyState(cs, isDark)
                  : _buildMarketProductGrid(cs, _marketProducts, isDark),
        ),
      ],
    );
  }

  Widget _buildMarketFilterDropdown(ColorScheme cs, bool isDark, List<ProductModel> featured) {
    final selectedMarket = _mainMarkets.where((m) => m['key'] == _selectedMarket).firstOrNull;
    final selectedLabel = selectedMarket?['label'] as String ?? 'All Products';
    final selectedIcon = selectedMarket?['icon'] as IconData ?? Icons.public;
    final selectedColor = selectedMarket?['color'] as Color ?? cs.primary;

    final allCount = featured.length;
    final localCount = featured.where((p) {
      final c = (p.country ?? '').toLowerCase();
      return c.isEmpty || c.contains('tanzania') || c.contains('tz');
    }).length;
    final globalCount = featured.where((p) {
      final c = (p.country ?? '').toLowerCase();
      return c.isNotEmpty && !c.contains('tanzania') && !c.contains('tz');
    }).length;
    final counts = {'all': allCount, 'local': localCount, 'global': globalCount};

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.onSurface.withValues(alpha: 0.05) : cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08), width: 1),
      ),
      child: PopupMenuButton<String>(
        onSelected: (key) {
          HapticUtils.selection();
          _loadMarketProducts(key);
        },
        offset: const Offset(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
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
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${counts[_selectedMarket] ?? 0}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selectedColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
        itemBuilder: (context) => _mainMarkets.map((m) {
          final key = m['key'] as String;
          final label = m['label'] as String;
          final subtitle = m['subtitle'] as String;
          final icon = m['icon'] as IconData;
          final color = m['color'] as Color;
          final isSelected = _selectedMarket == key;
          final count = counts[key] ?? 0;

          return PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, size: 16, color: cs.primary),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountryFilterButton(ColorScheme cs, bool isDark) {
    final homeState = context.read<HomeCubit>().state;
    final countries = homeState is HomeLoaded ? homeState.countries : <Map<String, String>>[];

    final isCountrySelected = !_mainMarkets.any((m) => m['key'] == _selectedMarket);
    final selectedFlag = isCountrySelected
        ? CountryData.countries.where(
            (c) => c.name.toLowerCase() == _selectedMarket.toLowerCase(),
          ).firstOrNull?.flag
        : null;

    return GestureDetector(
      onTap: countries.isEmpty ? null : () => _showCountryPickerSheet(cs, isDark, countries),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isCountrySelected
              ? LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isCountrySelected ? null : (isDark ? cs.onSurface.withValues(alpha: 0.05) : cs.onSurface.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCountrySelected ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: isCountrySelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (countries.isEmpty) ...[
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(cs.onSurface.withValues(alpha: 0.3)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading countries...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ] else if (isCountrySelected) ...[
              if (selectedFlag != null) ...[
                Text(selectedFlag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Text(
                _selectedMarket,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticUtils.selection();
                  _loadMarketProducts('all');
                },
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
            ] else ...[
              Icon(Icons.public, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Text(
                'Filter by Country',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${countries.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCountryPickerSheet(ColorScheme cs, bool isDark, List<Map<String, String>> countries) {
    List<Map<String, String>> filtered = List.from(countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.public, color: cs.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('Select Country',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (value) {
                        setModalState(() {
                          filtered = countries.where((c) {
                            final name = c['name']?.toLowerCase() ?? '';
                            final code = c['code']?.toLowerCase() ?? '';
                            final q = value.toLowerCase();
                            return name.contains(q) || code.contains(q);
                          }).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: cs.onSurface.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final country = filtered[index];
                        final name = country['name'] ?? '';
                        final flag = CountryData.countries.where(
                          (c) => c.name.toLowerCase() == name.toLowerCase(),
                        ).firstOrNull?.flag ?? '🏳️';
                        final isSelected = _selectedMarket == name;

                        return ListTile(
                          leading: Text(flag, style: const TextStyle(fontSize: 24)),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, size: 18, color: cs.primary)
                              : null,
                          onTap: () {
                            HapticUtils.selection();
                            Navigator.pop(ctx);
                            _loadMarketProducts(name);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarketLoadingGrid(ColorScheme cs, bool isDark) {
    return GridView.builder(
      key: ValueKey('loading_$_selectedMarket'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketEmptyState(ColorScheme cs, bool isDark) {
    final mainMarket = _mainMarkets.where((m) => m['key'] == _selectedMarket).firstOrNull;
    final Color color;
    final IconData icon;
    final String label;

    if (mainMarket != null) {
      color = mainMarket['color'] as Color;
      icon = mainMarket['icon'] as IconData;
      label = mainMarket['label'] as String;
    } else {
      color = cs.primary;
      icon = Icons.public;
      label = _selectedMarket;
    }

    return Container(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 28, color: color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No products in $label yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon — new products arriving daily',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketProductGrid(ColorScheme cs, List<ProductModel> products, bool isDark) {
    return GridView.builder(
      key: ValueKey('grid_${_selectedMarket}_${products.length}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length > 6 ? 6 : products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildMarketProductCard(cs, product, isDark);
      },
    );
  }

  Widget _buildMarketProductCard(ColorScheme cs, ProductModel product, bool isDark) {
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
                              color: cs.primary.withValues(alpha: 0.06),
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
                            color: cs.primary.withValues(alpha: 0.06),
                            child: Center(
                              child: Icon(Icons.inventory_2_outlined, size: 28, color: cs.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                        )
                      : Container(
                          height: 130,
                          color: cs.surfaceContainerHighest,
                          child: Center(
                            child: Icon(Icons.inventory_2_outlined, size: 28, color: cs.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                ),
                if (product.country != null && product.country!.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.country!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.categoryName != null)
                      Text(
                        product.categoryName!,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.rating > 0)
                          Row(
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.amber.shade700),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildDiscoverMix(ColorScheme colorScheme, List<ProductModel> featured) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<RecommendationCubit, RecommendationState>(
      builder: (context, state) {
        final recLoaded = state is RecommendationLoaded;

        // Combine all available product sources — mixed and dynamic
        final all = <ProductModel>[
          if (recLoaded) ...state.trending,
          if (recLoaded) ...state.newArrivals,
          if (recLoaded) ...state.topRated,
          if (recLoaded) ...state.bestSellers,
          if (recLoaded) ...state.recommended.map((r) => r.product),
          ...featured,
        ];

        // De-duplicate by id while preserving order
        final seen = <String>{};
        final unique = all.where((p) {
          final key = p.id;
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();

        if (unique.isEmpty) {
          // Shimmer-like skeleton placeholders
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                'Discover Mix',
                'See all',
                colorScheme,
                icon: Icons.explore_outlined,
                onActionTap: () =>
                    context.push(AppConstants.exploreProductsRoute),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Shuffle so the mix changes on every rebuild
        unique.shuffle();

        final mixed = unique.take(20).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              'Discover Mix',
              'See all',
              colorScheme,
              icon: Icons.explore_outlined,
              onActionTap: () =>
                  context.push(AppConstants.exploreProductsRoute),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: mixed.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildDiscoverCard(
                      colorScheme, mixed[index], isDark);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscoverCard(
    ColorScheme colorScheme,
    ProductModel product,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push(
        AppConstants.productDetailRoute,
        extra: {
          'product': product,
          'category': product.categoryName ?? 'All',
        },
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: product.thumbnailUrl != null
                      ? Image.network(
                          product.thumbnailUrl!,
                          height: 140,
                          width: 160,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 140,
                              width: 160,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.06),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => _discoverPlaceholder(
                              colorScheme, product.categoryName),
                        )
                      : _discoverPlaceholder(
                          colorScheme, product.categoryName),
                ),
                if ((product.categoryName ?? '').isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                        ),
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
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.rating > 0)
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 10, color: Colors.amber.shade700),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
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

  Widget _discoverPlaceholder(ColorScheme colorScheme, String? category) {
    return Container(
      height: 140,
      width: 160,
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.local_offer_outlined,
          size: 28,
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildFlashSaleBanner(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.flashDealsRoute),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
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
                      colorScheme.primary.withValues(alpha: 0.75),
                      colorScheme.primary.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_outlined, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'FLASH SALE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Up to 50% OFF — Limited time offers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(
    ColorScheme colorScheme,
    List<ProductModel> products,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return SizedBox(
        height: 500,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => Container(
            width: 168,
            height: 500,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
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

    // Pair products into rows of 2
    final pairs = <List<ProductModel>>[];
    for (int i = 0; i < products.length; i += 2) {
      pairs.add(products.sublist(i, i + 2 > products.length ? products.length : i + 2));
    }

    return SizedBox(
      height: 500,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: pairs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pair = pairs[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: pair.map((p) => Padding(
              padding: EdgeInsets.only(bottom: pair.length > 1 ? 12 : 0),
              child: _buildProductCard(colorScheme, p, isDark),
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    ColorScheme colorScheme,
    ProductModel product,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push(
        AppConstants.productDetailRoute,
        extra: {
          'product': product,
          'category': product.categoryName ?? 'All',
        },
      ),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 12,
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
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                  child: product.thumbnailUrl != null
                      ? Image.network(
                          product.thumbnailUrl!,
                          height: 145,
                          width: 168,
                          fit: BoxFit.cover,
                          loadingBuilder:
                              (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 145,
                              width: 168,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.06),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => _featuredPlaceholder(
                              colorScheme, product.categoryName),
                        )
                      : _featuredPlaceholder(
                          colorScheme, product.categoryName),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star,
                                  size: 11,
                                  color: Colors.amber.shade700),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
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
            // Flash Deals — first for urgency
            if (state.flashDeals.isNotEmpty) ...[
              _buildSectionTitle(
                'Flash Deals',
                'See all',
                colorScheme,
                icon: Icons.bolt_outlined,
                onActionTap: () => context.push(AppConstants.flashDealsRoute),
              ),
              const SizedBox(height: 14),
              _buildFlashDealsCarousel(colorScheme, state.flashDeals),
              const SizedBox(height: 28),
            ],
            // For You — personalized
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
            // Top Stores — break up product carousels with store content
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
            // Trending Now
            if (state.trending.isNotEmpty) ...[
              _buildSectionTitle(
                'Trending Now',
                'See all',
                colorScheme,
                icon: Icons.local_fire_department_outlined,
                onActionTap: () => context.push(AppConstants.trendingRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.trending),
              const SizedBox(height: 28),
            ],
            // Available Coupons — break up products with savings content
            if (state.coupons.isNotEmpty) ...[
              _buildSectionTitle(
                'Available Coupons',
                'See all',
                colorScheme,
                icon: Icons.local_offer_outlined,
                onActionTap: () => context.push(AppConstants.couponsRoute),
              ),
              const SizedBox(height: 14),
              _buildCouponsCarousel(colorScheme, state.coupons),
              const SizedBox(height: 28),
            ],
            // New Arrivals
            if (state.newArrivals.isNotEmpty) ...[
              _buildSectionTitle(
                'New Arrivals',
                'See all',
                colorScheme,
                icon: Icons.bolt_outlined,
                onActionTap: () => context.push(AppConstants.newArrivalsRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.newArrivals),
              const SizedBox(height: 28),
            ],
            // Recently Viewed — last for personal context
            if (state.recentlyViewed.isNotEmpty) ...[
              _buildSectionTitle(
                'Recently Viewed',
                'See all',
                colorScheme,
                icon: Icons.history_outlined,
                onActionTap: () => context.push(AppConstants.recentlyViewedRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.recentlyViewed),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFlashDealsCarousel(
      ColorScheme cs, List<FlashDealModel> deals) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: deals.length,
        itemBuilder: (context, index) {
          final deal = deals[index];
          final product = deal.product;
          return GestureDetector(
            onTap: () => context.push(AppConstants.productDetailRoute,
                extra: {'product': product, 'category': product.categoryName ?? 'All'}),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: product.thumbnailUrl != null
                            ? Image.network(product.thumbnailUrl!,
                                width: 140, height: 100, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 140, height: 100,
                                    color: cs.primary.withValues(alpha: 0.08),
                                    child: Icon(Icons.inventory_2_outlined,
                                        color: cs.primary, size: 28)))
                            : Container(
                                width: 140, height: 100,
                                color: cs.primary.withValues(alpha: 0.08),
                                child: Icon(Icons.inventory_2_outlined,
                                    color: cs.primary, size: 28)),
                      ),
                      Positioned(
                        top: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
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
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCarousel(
      ColorScheme cs, List<RecommendedProductModel> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final product = item.product;
          return GestureDetector(
            onTap: () => context.push(AppConstants.productDetailRoute,
                extra: {'product': product, 'category': product.categoryName ?? 'All'}),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.thumbnailUrl != null
                        ? Image.network(product.thumbnailUrl!,
                            width: 140, height: 110, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 140, height: 110,
                                color: cs.primary.withValues(alpha: 0.08),
                                child: Icon(Icons.inventory_2_outlined,
                                    color: cs.primary, size: 32)))
                        : Container(
                            width: 140, height: 110,
                            color: cs.primary.withValues(alpha: 0.08),
                            child: Icon(Icons.inventory_2_outlined,
                                color: cs.primary, size: 32)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
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
          );
        },
      ),
    );
  }

  Widget _buildProductCarousel(ColorScheme cs, List<ProductModel> products) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => context.push(AppConstants.productDetailRoute,
                extra: {'product': product, 'category': product.categoryName ?? 'All'}),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.thumbnailUrl != null
                        ? Image.network(product.thumbnailUrl!,
                            width: 130, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 130, height: 100,
                                color: cs.primary.withValues(alpha: 0.08),
                                child: Icon(Icons.inventory_2_outlined,
                                    color: cs.primary, size: 28)))
                        : Container(
                            width: 130, height: 100,
                            color: cs.primary.withValues(alpha: 0.08),
                            child: Icon(Icons.inventory_2_outlined,
                                color: cs.primary, size: 28)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (product.rating > 0)
                          Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber[600]),
                              const SizedBox(width: 2),
                              Text(product.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(product.formattedPrice,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
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

// _CategoryItem removed — real CategoryModel is used from API
