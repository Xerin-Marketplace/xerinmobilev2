import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';
import '../../cubit/recommendation_cubit.dart';
import '../../cubit/recommendation_state.dart';

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
  }

  @override
  void dispose() {
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
        final orders = homeState is HomeLoaded
            ? homeState.orders
            : <OrderModel>[];
        final searchResults = homeState is HomeLoaded
            ? homeState.searchResults
            : <ProductModel>[];
        final isLoadingData = homeState is HomeLoading;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(colorScheme, userName: user?.fullName ?? 'Guest'),
                const SizedBox(height: 20),
                _buildSearchBar(colorScheme),
                const SizedBox(height: 16),
                _buildPromoBanner(colorScheme),
                const SizedBox(height: 24),
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResults(colorScheme, searchResults, isLoadingData),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildSectionTitle(
                    'Categories',
                    'See all',
                    colorScheme,
                    icon: Icons.category_rounded,
                    onActionTap: () => context.push(AppConstants.categoriesRoute),
                  ),
                  const SizedBox(height: 14),
                  _buildCategories(colorScheme, categories, isLoadingData),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    'Featured',
                    'See all',
                    colorScheme,
                    icon: Icons.star_rounded,
                    onActionTap: () => context.push(AppConstants.exploreProductsRoute),
                  ),
                  const SizedBox(height: 14),
                  _buildFeaturedProducts(colorScheme, featured, isLoadingData),
                  const SizedBox(height: 24),
                  _buildRecommendationSections(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Recent Orders', '', colorScheme, icon: Icons.shopping_bag_rounded),
                  const SizedBox(height: 14),
                  _buildRecentOrders(colorScheme, orders),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, {required String userName}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                  backgroundImage: const AssetImage('assets/images/avatar.png'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
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
            _iconBadge(
              Icons.notifications_outlined,
              badge: '',
              colorScheme: colorScheme,
              onTap: () => _showNotificationsPopup(context, colorScheme),
            ),
            const SizedBox(width: 8),
            _iconBadge(
              Icons.favorite_outline_rounded,
              badge: '',
              colorScheme: colorScheme,
              onTap: () => _showWishlistPopup(context, colorScheme),
            ),
          ],
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
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                size: 26,
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
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.notifications_rounded, color: colorScheme.primary, size: 18),
        ),
        title: Text(
          notification['title']!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
      icon: Icons.favorite_rounded,
      items: items,
      itemBuilder: (item) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite_rounded, color: Color(0xFFE53935), size: 18),
        ),
        title: Text(
          item['name']!,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    return GestureDetector(
      onTap: () => context.push(AppConstants.promotionsRoute),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deals & Promotions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check out the latest offers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchNode.hasFocus
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.08),
          width: _searchNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: _searchNode.hasFocus
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.35),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchNode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              onChanged: (v) {
                final q = v.trim();
                setState(() => _searchQuery = q.toLowerCase());
                context.read<HomeCubit>().searchProducts(q);
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  Icons.close_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showFilterSheet(context, colorScheme),
            child: Container(
              margin: const EdgeInsets.all(4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => context.push(AppConstants.searchRoute),
            child: Container(
              margin: const EdgeInsets.all(4),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.search_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 16),
            ),
          ),
          const SizedBox(width: 4),
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
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
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
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
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
                            child: Icon(Icons.tune_rounded,
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
                title.contains('Category') ? Icons.category_rounded
                  : title.contains('Region') ? Icons.location_on_rounded
                  : Icons.attach_money_rounded,
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
    IconData icon = Icons.dashboard_rounded,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
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
    if (isLoading) {
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, _) => Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(child: Text('No categories', style: TextStyle(fontSize: 13))),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
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
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts(
    ColorScheme colorScheme,
    List<ProductModel> products,
    bool isLoading,
  ) {
    if (isLoading) {
      return SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (_, _) => Container(
            width: 160,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
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

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
                            top: Radius.circular(10)),
                        child: product.thumbnailUrl != null
                            ? Image.network(
                                product.thumbnailUrl!,
                                height: 130,
                                width: 160,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 130,
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
                                errorBuilder: (_, _, _) => _featuredPlaceholder(
                                    colorScheme, product.categoryName),
                              )
                            : _featuredPlaceholder(
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
                            Icons.favorite_outline_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
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
                                  fontSize: 13,
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
                                    Icon(Icons.star_rounded,
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
        },
      ),
    );
  }

  Widget _featuredPlaceholder(ColorScheme colorScheme, String? category) {
    return Container(
      height: 130,
      width: 160,
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
            if (state.flashDeals.isNotEmpty) ...[
              _buildSectionTitle(
                'Flash Deals',
                'See all',
                colorScheme,
                icon: Icons.flash_on_rounded,
                onActionTap: () => context.push(AppConstants.flashDealsRoute),
              ),
              const SizedBox(height: 14),
              _buildFlashDealsCarousel(colorScheme, state.flashDeals),
              const SizedBox(height: 24),
            ],
            if (state.recommended.isNotEmpty) ...[
              _buildSectionTitle(
                'For You',
                'See all',
                colorScheme,
                icon: Icons.auto_awesome_rounded,
                onActionTap: () => context.push(AppConstants.forYouRoute),
              ),
              const SizedBox(height: 14),
              _buildRecommendedCarousel(colorScheme, state.recommended),
              const SizedBox(height: 24),
            ],
            if (state.trending.isNotEmpty) ...[
              _buildSectionTitle(
                'Trending Now',
                'See all',
                colorScheme,
                icon: Icons.local_fire_department_rounded,
                onActionTap: () => context.push(AppConstants.trendingRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.trending),
              const SizedBox(height: 24),
            ],
            if (state.newArrivals.isNotEmpty) ...[
              _buildSectionTitle(
                'New Arrivals',
                'See all',
                colorScheme,
                icon: Icons.new_releases_rounded,
                onActionTap: () => context.push(AppConstants.newArrivalsRoute),
              ),
              const SizedBox(height: 14),
              _buildProductCarousel(colorScheme, state.newArrivals),
              const SizedBox(height: 24),
            ],
            if (state.stores.isNotEmpty) ...[
              _buildSectionTitle(
                'Top Stores',
                'See all',
                colorScheme,
                icon: Icons.storefront_rounded,
                onActionTap: () => context.push(AppConstants.storesRoute),
              ),
              const SizedBox(height: 14),
              _buildStoresCarousel(colorScheme, state.stores),
              const SizedBox(height: 24),
            ],
            if (state.coupons.isNotEmpty) ...[
              _buildSectionTitle(
                'Available Coupons',
                'See all',
                colorScheme,
                icon: Icons.local_offer_rounded,
                onActionTap: () => context.push(AppConstants.couponsRoute),
              ),
              const SizedBox(height: 14),
              _buildCouponsCarousel(colorScheme, state.coupons),
              const SizedBox(height: 24),
            ],
            if (state.recentlyViewed.isNotEmpty) ...[
              _buildSectionTitle(
                'Recently Viewed',
                'See all',
                colorScheme,
                icon: Icons.history_rounded,
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
                            Icon(Icons.auto_awesome_rounded, size: 10, color: cs.primary),
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
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
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
                                    Icon(Icons.store_rounded, color: cs.primary)),
                          )
                        : Icon(Icons.store_rounded, color: cs.primary),
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
                              Icon(Icons.verified_rounded, size: 14, color: cs.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (store.rating > 0) ...[
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber[600]),
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
                Icon(Icons.local_offer_rounded, color: cs.primary, size: 24),
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

  Widget _buildRecentOrders(ColorScheme colorScheme, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your recent orders will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: orders.take(3).map((order) {
        final statusColor = _orderStatusColor(order.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderRef,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.createdAt ?? 'Recent',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.formattedTotal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _orderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}

// _CategoryItem removed — real CategoryModel is used from API
