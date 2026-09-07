import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../cubit/review_cubit.dart';
import '../../data/models/review_model.dart';

class ProductReviewsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewsPage({
    super.key,
    required this.productId,
    this.productName = 'Product',
  });

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  late final ReviewCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ReviewCubit>()..loadProductReviews(widget.productId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Reviews · ${widget.productName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          elevation: 0,
        ),
        body: BlocBuilder<ReviewCubit, ReviewState>(
          builder: (context, state) {
            if (state is ReviewLoading || state is ReviewInitial) {
              return Center(child: CircularProgressIndicator(color: cs.primary));
            }
            if (state is ReviewError) {
              return _buildError(state, cs);
            }
            if (state is ReviewsLoaded) {
              if (state.reviews.isEmpty) {
                return _buildEmpty(cs);
              }
              return RefreshIndicator(
                onRefresh: () => _cubit.loadProductReviews(widget.productId),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildRatingHeader(state, cs),
                    const SizedBox(height: 16),
                    ...state.reviews.map((r) => _ReviewCard(review: r)),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRatingHeader(ReviewsLoaded state, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                state.averageRating > 0 ? state.averageRating.toStringAsFixed(1) : '0.0',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < state.averageRating.round() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.total} ${state.total == 1 ? "review" : "reviews"}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Feedback',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified ratings and feedback from verified purchasers.',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to review this product after purchasing!',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ReviewError state, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _cubit.loadProductReviews(widget.productId),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = (review.customerName != null && review.customerName!.isNotEmpty)
        ? review.customerName![0].toUpperCase()
        : 'U';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName ?? 'Anonymous Customer',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < review.rating ? Icons.star : Icons.star_border,
                                color: const Color(0xFFF59E0B),
                                size: 14,
                              );
                            }),
                          ),
                          if (review.createdAt != null && review.createdAt!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              review.createdAt!.split('T').first,
                              style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (review.verifiedPurchase)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Verified Purchase',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                    ),
                  ),
              ],
            ),
            if (review.title != null && review.title!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.title!,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface),
              ),
            ],
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                review.comment!,
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.75), height: 1.4),
              ),
            ],
            if (review.sellerReply != null && review.sellerReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Seller Response',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.sellerReply!,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
