import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<RecommendationCubit>();
      if (cubit.state is RecommendationInitial) {
        cubit.loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<RecommendationCubit, RecommendationState>(
          builder: (context, state) {
            if (state is RecommendationLoading ||
                state is RecommendationInitial) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }

            if (state is RecommendationLoaded) {
              final flashDeals = state.flashDeals;
              final trending = state.trending;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Flash Deals & Trending',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface)),
                                const SizedBox(height: 2),
                                Text(
                                  '${flashDeals.length} deals · ${trending.length} trending',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Flash deals — horizontal cards at top
                  if (flashDeals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildFlashDealsHeader(colorScheme),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: flashDeals.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                              _buildFlashDealCard(flashDeals[index], colorScheme),
                        ),
                      ),
                    ),
                  ],
                  // Trending — grid below
                  if (trending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('Trending Now', colorScheme),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductGridCard(
                              trending[index], colorScheme),
                          childCount: trending.length,
                        ),
                      ),
                    ),
                  ],
                  if (flashDeals.isEmpty && trending.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Text('No products available',
                            style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurface.withValues(alpha: 0.4))),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildFlashDealsHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text('Flash Deals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(width: 8),
          const Text('HOT',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
        ],
      ),
    );
  }

  Widget _buildFlashDealCard(FlashDealModel deal, ColorScheme cs) {
    final product = deal.product;
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute,
          extra: {'product': product, 'category': product.categoryName ?? 'All'}),
      child: Container(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.thumbnailUrl != null
                      ? Image.network(product.thumbnailUrl!,
                          width: double.infinity, height: 120, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: double.infinity, height: 120,
                              color: cs.surfaceContainerHighest))
                      : Container(
                          width: double.infinity, height: 120,
                          color: cs.surfaceContainerHighest),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    '-${deal.discountPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(deal.formattedDealPrice,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                      const SizedBox(width: 8),
                      Text(deal.formattedOriginalPrice,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.35),
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  if (deal.remainingTime != null && deal.isActive) ...[
                    const SizedBox(height: 8),
                    _buildCountdown(deal.remainingTime!, cs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown(Duration remaining, ColorScheme cs) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
    );
  }

  Widget _buildProductGridCard(ProductModel product, ColorScheme cs) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute,
          extra: {'product': product, 'category': product.categoryName ?? 'All'}),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: product.thumbnailUrl != null
                    ? Image.network(product.thumbnailUrl!,
                        width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceContainerHighest))
                    : Container(
                        color: cs.surfaceContainerHighest),
              ),
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
                  if (product.rating > 0) ...[
                    const SizedBox(height: 4),
                    Text(product.rating.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                  const SizedBox(height: 4),
                  Text(product.formattedPrice,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
