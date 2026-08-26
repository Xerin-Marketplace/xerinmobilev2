import 'package:flutter/material.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../../customer/data/datasources/review_remote_datasource.dart';
import '../../../customer/data/models/review_model.dart';

class SellerReviewsPage extends StatefulWidget {
  const SellerReviewsPage({super.key});

  @override
  State<SellerReviewsPage> createState() => _SellerReviewsPageState();
}

class _SellerReviewsPageState extends State<SellerReviewsPage> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ds = sl<ReviewRemoteDataSource>();
      final reviews = await ds.getSellerReviews();
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadReviews, child: const Text('Retry')),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Uicons.star, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No reviews yet', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) => _buildReviewCard(context, _reviews[index]),
                      ),
                    ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                      i < review.rating.round() ? Uicons.star : Uicons.star,
                      size: 16,
                      color: i < review.rating.round() ? Colors.amber : Colors.grey.shade300,
                    )),
                const SizedBox(width: 8),
                Text(review.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            if (review.comment != null && review.comment!.isNotEmpty)
              Text(review.comment!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            if (review.sellerReply != null && review.sellerReply!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(review.sellerReply!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReplyDialog(context, review),
                  icon: const Icon(Uicons.reply, size: 16),
                  label: const Text('Reply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, ReviewModel review) {
    final replyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to Review'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: replyController,
            decoration: const InputDecoration(
              labelText: 'Your Reply *',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  final ds = sl<ReviewRemoteDataSource>();
                  await ds.sellerReplyReview(reviewId: review.id, reply: replyController.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reply sent'), backgroundColor: Colors.green),
                    );
                    _loadReviews();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
