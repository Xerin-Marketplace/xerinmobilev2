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
import '../../data/datasources/customer_remote_datasource.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/wishlist_cubit.dart';
import '../cubit/wishlist_state.dart';
import '../cubit/review_cubit.dart';

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
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();
  late final ReviewCubit _reviewCubit;
  String? _eligibleOrderItemId;
  bool _checkingEligibility = true;

  @override
  void initState() {
    super.initState();
    _reviewCubit = sl<ReviewCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWishlistStatus();
      _reviewCubit.loadProductReviews(widget.product.id);
      _checkReviewEligibility();
    });
  }

  void _checkWishlistStatus() {
    final wishlistState = context.read<WishlistCubit>().state;
    if (wishlistState is WishlistLoaded) {
      setState(() {
        _isWishlisted =
            wishlistState.items.any((i) => i.productId == widget.product.id);
      });
    }
  }

  void _toggleWishlist() {
    context
        .read<WishlistCubit>()
        .toggleProductWishlist(productId: widget.product.id);
    setState(() => _isWishlisted = !_isWishlisted);
    NotificationService().success(
      _isWishlisted
          ? '${widget.product.name} added to wishlist'
          : '${widget.product.name} removed from wishlist',
    );
  }

  Future<void> _checkReviewEligibility() async {
    try {
      final customerDs = sl<CustomerRemoteDataSource>();
      final orders = await customerDs.getOrders(pageSize: 50);
      String? foundItemId;
      for (final order in orders) {
        if (order.status == 'delivered' || order.status == 'completed') {
          for (final item in order.items) {
            if (item.productId == widget.product.id) {
              foundItemId = item.id;
              break;
            }
          }
          if (foundItemId != null) break;
        }
      }
      if (mounted) {
        setState(() {
          _eligibleOrderItemId = foundItemId;
          _checkingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingEligibility = false);
      }
    }
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
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.homeRoute);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? const Color(0xFFE53935) : null,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image gallery
            SizedBox(
              height: 300,
              width: double.infinity,
              child: p.images.isNotEmpty
                  ? PageView.builder(
                      controller: _imagePageController,
                      itemCount: p.images.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, index) {
                        return Image.network(
                          ApiConstants.resolveImageUrl(p.images[index]) ?? '',
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 300,
                              color: colorScheme.primary.withValues(alpha: 0.06),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => Container(
                            height: 300,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 300,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
            ),

            // Thumbnail strip
            if (p.images.length > 1)
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: p.images.length,
                  itemBuilder: (context, index) {
                    final isSelected = _currentImageIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _imagePageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
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
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiConstants.resolveImageUrl(p.images[index]) ?? '',
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: colorScheme.primary.withValues(alpha: 0.06),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_outlined,
                                size: 20,
                                color: colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (p.categoryName != null)
                    Text(
                      p.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p.formattedPrice,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (p.salePrice != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${p.currency} ${p.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating
                  BlocBuilder<ReviewCubit, ReviewState>(
                    bloc: _reviewCubit,
                    builder: (context, reviewState) {
                      double rating = p.rating;
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
                                Icons.star,
                                size: 16,
                                color: index < rating.round()
                                    ? Colors.amber.shade600
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.15),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${rating.toStringAsFixed(1)}${reviewCount > 0 ? ' ($reviewCount)' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    p.description ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Specifications
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSpecRow('SKU', p.sku.isNotEmpty ? p.sku : 'N/A', colorScheme),
                  _buildSpecRow('Category', p.categoryName ?? 'N/A', colorScheme),
                  _buildSpecRow('Currency', p.currency, colorScheme),
                  if (p.weight != null && p.weight!.isNotEmpty)
                    _buildSpecRow('Weight', p.weight!, colorScheme),
                  if (p.country != null && p.country!.isNotEmpty)
                    _buildSpecRow('Country', p.country!, colorScheme),
                  _buildSpecRow('Status', p.status.toUpperCase(), colorScheme),
                  _buildSpecRow('Listed', p.createdAt ?? 'N/A', colorScheme),
                ],
              ),
            ),

            const Divider(),

            // Reviews
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildReviewsSection(colorScheme),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (GuestAuthGate.isGuest) {
                        GuestAuthGate.showPrompt(
                          context,
                          title: 'Sign In to Add to Cart',
                          message:
                              'Create an account or sign in to add items to your cart.',
                        );
                        return;
                      }
                      context.read<CartCubit>().addToCart(
                        productId: p.id,
                        quantity: 1,
                      );
                      setState(() => _added = true);
                      NotificationService().success('${p.name} added to cart');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(_added ? Icons.check : Icons.shopping_cart_outlined, size: 20),
                    label: Text(
                      _added ? 'Added' : 'Add to Cart',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      if (GuestAuthGate.isGuest) {
                        GuestAuthGate.showPrompt(
                          context,
                          title: 'Sign In to Buy Now',
                          message: 'Sign in to complete your purchase.',
                        );
                        return;
                      }
                      context.read<CartCubit>().addToCart(
                        productId: p.id,
                        quantity: 1,
                      );
                      context.go(AppConstants.homeRoute);
                      NotificationService().info('Proceeding to checkout for ${p.name}');
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 14,
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
    );
  }

  Widget _buildSpecRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(ColorScheme colorScheme) {
    return BlocProvider.value(
      value: _reviewCubit,
      child: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          int totalReviews = 0;
          List<ReviewModel> reviews = [];

          if (state is ReviewsLoaded) {
            totalReviews = state.total;
            reviews = state.reviews.take(3).toList();
          }

          return Column(
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
              const SizedBox(height: 12),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else
                Column(
                  children:
                      reviews.map((r) => _buildReviewItem(r, colorScheme)).toList(),
                ),
              if (_eligibleOrderItemId != null && !_checkingEligibility) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(context, colorScheme),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Write Review'),
                  ),
                ),
              ],
            ],
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
                    Text(
                      review.customerName ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Icon(
                            Icons.star,
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
                          color: i < rating
                              ? Colors.amber
                              : colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      child: FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                _reviewCubit
                                    .submitProductReview(
                                  productId: widget.product.id,
                                  orderItemId: _eligibleOrderItemId!,
                                  rating: rating,
                                  comment: commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                )
                                    .then((_) {
                                  Navigator.pop(ctx);
                                  NotificationService()
                                      .success('Review submitted successfully');
                                });
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Review'),
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
}
