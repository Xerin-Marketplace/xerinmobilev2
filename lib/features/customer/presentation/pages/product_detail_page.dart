import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../data/models/product_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationCubit>().loadRelatedProducts(widget.product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        widget.product.thumbnailUrl != null
                            ? Image.network(
                                widget.product.thumbnailUrl!,
                                height: 320,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 320,
                                width: double.infinity,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 64,
                                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                        Positioned(
                          top: 16,
                          left: 20,
                          child: GestureDetector(
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
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: colorScheme.onSurface,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite_outline_rounded,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.product.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.product.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.formattedPrice,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildReviewsSection(colorScheme),
                          const SizedBox(height: 20),
                          // Xerin Logistics badges
                          Row(
                            children: [
                              Expanded(child: _buildXerinBadge(Icons.verified_user_rounded, 'Verified Seller', 'Quality-checked', colorScheme)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildXerinBadge(Icons.inventory_2_rounded, 'Fulfilled by Xerin', 'Quality dispatch', colorScheme)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildXerinBadge(Icons.shield_rounded, 'Buyer Protection', 'Secure payment hold', colorScheme)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildXerinBadge(Icons.local_shipping_rounded, 'Xerin Express', 'Fast delivery', colorScheme)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.product.description ??
                                'This premium ${widget.product.name.toLowerCase()} offers excellent quality, durability, and style. Perfect for everyday use. Order now and get fast delivery anywhere in Tanzania.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              _buildFeature('Delivery by Xerin Express', colorScheme),
                              _buildFeature('Buyer Protection — funds held securely', colorScheme),
                              _buildFeature('7-day return policy', colorScheme),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Price',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.product.formattedPrice,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () {
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
                                    : colorScheme.onSurface.withValues(alpha: 0.05),
                                foregroundColor: _added
                                    ? Colors.white
                                    : colorScheme.onSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: Icon(
                                _added
                                    ? Icons.check_rounded
                                    : Icons.shopping_cart_outlined,
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
                                  borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 28),
                    _buildRelatedProducts(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXerinBadge(IconData icon, String title, String subtitle, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(subtitle, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts(ColorScheme colorScheme) {
    return BlocBuilder<RecommendationCubit, RecommendationState>(
      builder: (context, state) {
        if (state is RelatedProductsLoaded && state.products.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Related Products',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return GestureDetector(
                      onTap: () => context.pushReplacement(AppConstants.productDetailRoute,
                          extra: {'product': product, 'category': product.categoryName ?? 'All'}),
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
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
                                          color: colorScheme.primary.withValues(alpha: 0.08),
                                          child: Icon(Icons.inventory_2_outlined,
                                              color: colorScheme.primary, size: 28)))
                                  : Container(
                                      width: 130, height: 100,
                                      color: colorScheme.primary.withValues(alpha: 0.08),
                                      child: Icon(Icons.inventory_2_outlined,
                                          color: colorScheme.primary, size: 28)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(product.formattedPrice,
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.bold,
                                          color: colorScheme.primary)),
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
        return const SizedBox();
      },
    );
  }

  Widget _buildReviewsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < widget.product.rating.round()
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 18,
                color: Colors.amber.shade700,
              );
            }),
            const SizedBox(width: 8),
            Text(
              widget.product.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeature(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
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
