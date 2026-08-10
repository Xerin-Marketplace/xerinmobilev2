import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  @override
  void initState() {
    super.initState();
    context.read<ReviewCubit>().loadProductReviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews - ${widget.productName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReviewDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ReviewCubit, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReviewError) {
            return Center(child: Text(state.message));
          }
          if (state is ReviewsLoaded) {
            if (state.reviews.isEmpty) {
              return const Center(child: Text('No reviews yet'));
            }
            return Column(
              children: [
                if (state.averageRating > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < state.averageRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            Text('${state.total} reviews'),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.reviews.length,
                    itemBuilder: (context, index) {
                      final review = state.reviews[index];
                      return _ReviewCard(review: review);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    int rating = 5;
    final titleController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = i + 1),
                  );
                }),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(labelText: 'Comment'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<ReviewCubit>().submitProductReview(
                      productId: widget.productId,
                      rating: rating,
                      title: titleController.text.trim().isEmpty
                          ? null
                          : titleController.text.trim(),
                      comment: commentController.text.trim().isEmpty
                          ? null
                          : commentController.text.trim(),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Submit'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text((review.customerName ?? 'U')[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                if (review.verifiedPurchase)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Verified',
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
              ],
            ),
            if (review.title != null) ...[
              const SizedBox(height: 8),
              Text(review.title!, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (review.comment != null) ...[
              const SizedBox(height: 4),
              Text(review.comment!),
            ],
            if (review.sellerReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seller Reply',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(review.sellerReply!),
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
