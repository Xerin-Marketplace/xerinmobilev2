import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/constants/api_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/guest_auth_gate.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../cubit/review_cubit.dart';
import '../../../../core/theme/uicons.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final String category;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.category,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _added = false;
  bool _isWishlisted = false;
  int _selectedTab = 0;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();
  late final ReviewCubit _reviewCubit;

  @override
  void initState() {
    super.initState();
    _reviewCubit = sl<ReviewCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWishlistStatus();
      _reviewCubit.loadProductReviews(widget.product.id);
    });
  }

  void _checkWishlistStatus() {
    final wishlistState = context.read<WishlistCubit>().state;
    if (wishlistState is WishlistLoaded) {
      setState(() {
        _isWishlisted = wishlistState.items.any((i) => i.productId == widget.product.id);
      });
    }
  }

  void _toggleWishlist() {
    context.read<WishlistCubit>().toggleProductWishlist(productId: widget.product.id);
    setState(() => _isWishlisted = !_isWishlisted);
    NotificationService().success(
      _isWishlisted ? '${widget.product.name} added to wishlist' : '${widget.product.name} removed from wishlist',
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _reviewCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image gallery card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Gallery
                              GestureDetector(
                                onTap: () => _openFullscreenViewer(colorScheme),
                                child: SizedBox(
                                  height: 340,
                                  width: double.infinity,
                                  child: widget.product.images.isNotEmpty
                                      ? PageView.builder(
                                          controller: _imagePageController,
                                          itemCount: widget.product.images.length,
                                          onPageChanged: (i) => setState(() => _currentImageIndex = i),
                                          itemBuilder: (context, index) {
                                            return InteractiveViewer(
                                              clipBehavior: Clip.none,
                                              minScale: 0.8,
                                              maxScale: 4.0,
                                              child: Image.network(
                                                ApiConstants.resolveImageUrl(widget.product.images[index]) ?? '',
                                                height: 340,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return Container(
                                                    height: 340,
                                                    width: double.infinity,
                                                    color: colorScheme.primary.withValues(alpha: 0.06),
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (_, __, ___) => Container(
                                                  height: 340,
                                                  width: double.infinity,
                                                  color: colorScheme.primary.withValues(alpha: 0.06),
                                                  child: Icon(
                                                    Uicons.imageSlash,
                                                    size: 64,
                                                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          height: 340,
                                          width: double.infinity,
                                          color: colorScheme.primary.withValues(alpha: 0.06),
                                          child: Icon(
                                            Uicons.imageSlash,
                                            size: 64,
                                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                        ),
                                ),
                              ),
                              // Sale badge
                              if (widget.product.salePrice != null)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${((1 - widget.product.salePrice! / widget.product.price) * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              // Heart button
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: _toggleWishlist,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isWishlisted ? Icons.favorite : Icons.favorite_border,
                                      color: _isWishlisted
                                          ? const Color(0xFFE53935)
                                          : colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              // Image counter
                              if (widget.product.images.length > 1)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1} / ${widget.product.images.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              // Dot indicators
                              if (widget.product.images.length > 1)
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.product.images.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        width: _currentImageIndex == index ? 20 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _currentImageIndex == index
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Thumbnail strip
                    if (widget.product.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.product.images.length,
                            itemBuilder: (context, index) {
                              final isSelected = _currentImageIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  _imagePageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? colorScheme.primary : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      ApiConstants.resolveImageUrl(widget.product.images[index]) ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: colorScheme.primary.withValues(alpha: 0.06),
                                        child: Icon(Uicons.imageSlash, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    // Back button row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF252525) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Uicons.arrowBack,
                                color: colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<ReviewCubit, ReviewState>(
                            bloc: _reviewCubit,
                            builder: (context, reviewState) {
                              double rating = widget.product.rating;
                              if (reviewState is ReviewsLoaded && reviewState.averageRating > 0) {
                                rating = reviewState.averageRating;
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Uicons.star, size: 14, color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Product info card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.product.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                if (widget.product.salePrice != null) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    'TZS ${widget.product.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Rating stars - real data from reviews
                            BlocBuilder<ReviewCubit, ReviewState>(
                              bloc: _reviewCubit,
                              builder: (context, reviewState) {
                                double rating = widget.product.rating;
                                int reviewCount = 0;
                                if (reviewState is ReviewsLoaded) {
                                  if (reviewState.averageRating > 0) {
                                    rating = reviewState.averageRating;
                                  }
                                  reviewCount = reviewState.total;
                                }
                                return Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 2),
                                        child: Icon(
                                          Uicons.star,
                                          size: 16,
                                          color: index < rating.round()
                                              ? Colors.amber.shade600
                                              : colorScheme.onSurface.withValues(alpha: 0.15),
                                        ),
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${rating.toStringAsFixed(1)} / 5.0${reviewCount > 0 ? ' ($reviewCount)' : ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Two badge cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(child: _buildXerinBadge(Uicons.shieldCheck, 'Verified Seller', 'Quality-checked', colorScheme, isDark)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildXerinBadge(Uicons.box, 'Fulfilled by Xerin', 'Quality dispatch', colorScheme, isDark)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          Expanded(child: _buildXerinBadge(Uicons.shield, 'Buyer Protection', 'Secure payment hold', colorScheme, isDark)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildXerinBadge(Uicons.shippingFast, 'Xerin Express', 'Fast delivery', colorScheme, isDark)),
                        ],
                      ),
                    ),
                    // Description card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildDetailsCard(colorScheme, isDark),
                    ),
                    // Reviews card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildReviewsCard(colorScheme, isDark),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom checkout bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (GuestAuthGate.isGuest) {
                              GuestAuthGate.showPrompt(context,
                                title: 'Sign In to Add to Cart',
                                message: 'Create an account or sign in to add items to your cart and place orders.');
                              return;
                            }
                            context.read<CartCubit>().addToCart(
                              productId: widget.product.id,
                              quantity: 1,
                            );
                            setState(() => _added = true);
                            NotificationService().success('${widget.product.name} added to cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _added
                                ? const Color(0xFF22C55E)
                                : colorScheme.onSurface.withValues(alpha: 0.06),
                            foregroundColor: _added
                                ? Colors.white
                                : colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            _added ? Uicons.check : Uicons.shoppingCart,
                            size: 20,
                          ),
                          label: Text(
                            _added ? 'Added' : 'Add to Cart',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (GuestAuthGate.isGuest) {
                              GuestAuthGate.showPrompt(context,
                                title: 'Sign In to Buy Now',
                                message: 'Sign in to complete your purchase securely.');
                              return;
                            }
                            context.read<CartCubit>().addToCart(
                              productId: widget.product.id,
                              quantity: 1,
                            );
                            context.go(AppConstants.homeRoute);
                            NotificationService().info('Proceeding to checkout for ${widget.product.name}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  void _openFullscreenViewer(ColorScheme colorScheme) {
    if (widget.product.images.isEmpty) return;

    final fsController = PageController(initialPage: _currentImageIndex);
    int fsIndex = _currentImageIndex;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StatefulBuilder(
            builder: (context, setFSState) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: fsController,
                        itemCount: widget.product.images.length,
                        onPageChanged: (i) => setFSState(() => fsIndex = i),
                        itemBuilder: (context, index) {
                          return InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 5.0,
                            child: Center(
                              child: Image.network(
                                ApiConstants.resolveImageUrl(widget.product.images[index]) ?? '',
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Uicons.imageSlash,
                                    size: 64,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Close button
                      Positioned(
                        top: 16,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Uicons.crossSmall,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Counter
                      if (widget.product.images.length > 1)
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${fsIndex + 1} / ${widget.product.images.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewsCard(ColorScheme colorScheme, bool isDark) {
    return BlocProvider.value(
      value: _reviewCubit,
      child: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          double avgRating = widget.product.rating;
          int totalReviews = 0;
          List<ReviewModel> reviews = [];

          if (state is ReviewsLoaded) {
            avgRating = state.averageRating > 0 ? state.averageRating : widget.product.rating;
            totalReviews = state.total;
            reviews = state.reviews.take(3).toList();
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (totalReviews > 0)
                      GestureDetector(
                        onTap: () => context.push(
                          AppConstants.productReviewsRoute,
                          extra: {
                            'productId': widget.product.id,
                            'productName': widget.product.name,
                          },
                        ),
                        child: Text(
                          'See all ($totalReviews)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Rating summary
                Row(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  Uicons.star,
                                  size: 18,
                                  color: i < avgRating.round()
                                      ? Colors.amber.shade600
                                      : colorScheme.onSurface.withValues(alpha: 0.15),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalReviews == 0
                                ? 'No reviews yet'
                                : '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showReviewDialog(context, colorScheme),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Uicons.add, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Write Review',
                              style: TextStyle(
                                fontSize: 12,
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
                const SizedBox(height: 16),
                if (state is ReviewLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (state is ReviewError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Failed to load reviews',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                else if (reviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Uicons.star,
                            size: 36,
                            color: colorScheme.onSurface.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this product',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: reviews.map((review) => _buildReviewItem(review, colorScheme)).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  (review.customerName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.customerName ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (review.verifiedPurchase) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Icon(
                            Uicons.star,
                            size: 12,
                            color: i < review.rating
                                ? Colors.amber.shade600
                                : colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          const Divider(height: 20),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, ColorScheme colorScheme) {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setSheetState(() => rating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 36,
                          color: i < rating ? Colors.amber : colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Comment (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this product...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: colorScheme.onSurface.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<ReviewCubit, ReviewState>(
                  bloc: _reviewCubit,
                  builder: (context, state) {
                    final isSubmitting = state is ReviewSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                _reviewCubit.submitProductReview(
                                  productId: widget.product.id,
                                  rating: rating,
                                  comment: commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                ).then((_) {
                                  Navigator.pop(ctx);
                                  NotificationService().success('Review submitted successfully');
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsCard(ColorScheme colorScheme, bool isDark) {
    final p = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == 0
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Specifications',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == 1
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Padding(
            padding: const EdgeInsets.all(20),
            child: _selectedTab == 0
                ? _buildDescriptionTab(colorScheme)
                : _buildSpecificationsTab(colorScheme, p),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.description ??
              'This premium ${widget.product.name.toLowerCase()} offers excellent quality, durability, and style. Perfect for everyday use. Order now and get fast delivery anywhere in Tanzania.',
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        _buildFeature('Delivery by Xerin Express', colorScheme),
        _buildFeature('Buyer Protection — funds held securely', colorScheme),
        _buildFeature('7-day return policy', colorScheme),
      ],
    );
  }

  Widget _buildSpecificationsTab(ColorScheme colorScheme, ProductModel p) {
    final specs = <_SpecItem>[
      _SpecItem(Uicons.tags, 'Product ID', p.id),
      _SpecItem(Uicons.category, 'Category', p.categoryName ?? 'N/A'),
      _SpecItem(Uicons.box, 'SKU', p.sku.isNotEmpty ? p.sku : 'N/A'),
      _SpecItem(Uicons.coins, 'Currency', p.currency),
      _SpecItem(Uicons.wallet, 'Price', p.formattedPrice),
      if (p.salePrice != null)
        _SpecItem(Uicons.tags, 'Sale Price', '${p.currency} ${p.salePrice!.toStringAsFixed(0)}'),
      if (p.weight != null && p.weight!.isNotEmpty)
        _SpecItem(Uicons.shippingFast, 'Weight', p.weight!),
      _SpecItem(Uicons.storeAlt, 'Seller ID', p.sellerId),
      _SpecItem(Uicons.accessTime, 'Listed Date', p.createdAt ?? 'N/A'),
      _SpecItem(Uicons.checkCircle, 'Status', p.status.toUpperCase()),
    ];

    return Column(
      children: specs.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(s.icon, size: 16, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              s.label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                s.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildXerinBadge(IconData icon, String title, String subtitle, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Uicons.checkCircle,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem {
  final IconData icon;
  final String label;
  final String value;

  _SpecItem(this.icon, this.label, this.value);
}
