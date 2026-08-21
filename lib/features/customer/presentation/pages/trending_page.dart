import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../../../core/theme/uicons.dart';

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
      backgroundColor: colorScheme.surface,
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
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('Trending & Deals',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                    ),
                    leading: IconButton(
                      icon: Icon(Uicons.arrowBack,
                          color: colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  if (state.flashDeals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildFlashDealsBanner(colorScheme),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildFlashDealCard(state.flashDeals[index], colorScheme),
                          childCount: state.flashDeals.length,
                        ),
                      ),
                    ),
                  ],
                  if (state.trending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                          'Trending Now', Uicons.flame, colorScheme),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductGridCard(
                              state.trending[index], colorScheme),
                          childCount: state.trending.length,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildFlashDealsBanner(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE53935), const Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Uicons.bolt, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flash Deals',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Limited time offers — grab them before they\'re gone!',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashDealCard(FlashDealModel deal, ColorScheme cs) {
    final product = deal.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.2)),
      ),
      child: GestureDetector(
        onTap: () => context.push(AppConstants.productDetailRoute,
            extra: {'product': product, 'category': product.categoryName ?? 'All'}),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.thumbnailUrl != null
                        ? Image.network(product.thumbnailUrl!,
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 80, height: 80,
                                color: cs.primary.withValues(alpha: 0.08),
                                child: Icon(Uicons.box,
                                    color: cs.primary, size: 28)))
                        : Container(
                            width: 80, height: 80,
                            color: cs.primary.withValues(alpha: 0.08),
                            child: Icon(Uicons.box,
                                color: cs.primary, size: 28)),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: const BorderRadius.only(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(deal.formattedDealPrice,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFE53935))),
                        const SizedBox(width: 8),
                        Text(deal.formattedOriginalPrice,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.4),
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                    if (deal.remainingTime != null && deal.isActive) ...[
                      const SizedBox(height: 6),
                      _buildCountdown(deal.remainingTime!, cs),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdown(Duration remaining, ColorScheme cs) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    return Row(
      children: [
        Icon(Uicons.stopwatch, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(ProductModel product, ColorScheme cs) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute,
          extra: {'product': product, 'category': product.categoryName ?? 'All'}),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.thumbnailUrl != null
                    ? Image.network(product.thumbnailUrl!,
                        width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: cs.primary.withValues(alpha: 0.08),
                            child: Icon(Uicons.box,
                                color: cs.primary, size: 36)))
                    : Container(
                        color: cs.primary.withValues(alpha: 0.08),
                        child: Icon(Uicons.box,
                            color: cs.primary, size: 36)),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.rating > 0) ...[
                        Icon(Uicons.star, size: 12, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(product.rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
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
  }
}
