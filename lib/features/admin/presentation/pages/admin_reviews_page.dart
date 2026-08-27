import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/security/admin_access.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({super.key});

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadReviews(),
          ),
        ],
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminReviewsLoaded) {
            if (state.reviews.isEmpty) {
              return const Center(child: Text('No reviews found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.reviews.length,
              itemBuilder: (context, index) =>
                  _reviewCard(context, state.reviews[index]),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCubit>().loadReviews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (!_isReloading) {
            _isReloading = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AdminCubit>().loadReviews();
              _isReloading = false;
            });
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _reviewCard(BuildContext context, AdminReviewModel review) {
    final color = _statusColor(review.status);
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
                      i < review.rating ? Uicons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_humanize(review.status),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (review.productName != null)
              Text('Product: ${review.productName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (review.customerName != null)
              Text('By: ${review.customerName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (review.comment != null) ...[
              const SizedBox(height: 8),
              Text(review.comment!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 12),
            if (AdminAccess.canAccessItem(
                    GetIt.instance<TokenStorage>().currentUser,
                    'reviews.moderate'))
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => context.read<AdminCubit>().moderateReview(review.id, 'approved'),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () => context.read<AdminCubit>().moderateReview(review.id, 'rejected'),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () => context.read<AdminCubit>().moderateReview(review.id, 'pending'),
                    child: const Text('Pending'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
