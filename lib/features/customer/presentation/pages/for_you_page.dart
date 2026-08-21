import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/product_model.dart';
import '../../data/models/recommendation_model.dart';
import '../../../../core/theme/uicons.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<RecommendationCubit>();
      if (cubit.state is RecommendationInitial ||
          cubit.state is RecommendationError) {
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

            if (state is RecommendationError) {
              return _buildError(state.message, colorScheme);
            }

            if (state is RecommendationLoaded) {
              return _buildContent(state, colorScheme);
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildError(String message, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.circleExclamation,
                size: 64, color: cs.error.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<RecommendationCubit>().loadAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecommendationLoaded state, ColorScheme cs) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('For You',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
          ),
          leading: IconButton(
            icon: Icon(Uicons.arrowBack, color: cs.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        if (state.recommended.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildSectionHeader(
                'Recommended for You', Uicons.autoAwesome, cs),
          ),
        if (state.recommended.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = state.recommended[index];
                  return _buildRecommendedCard(item, cs);
                },
                childCount: state.recommended.length,
              ),
            ),
          ),
        if (state.newArrivals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
                'New Arrivals', Uicons.bolt, cs),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(state.newArrivals, cs),
          ),
        ],
        if (state.topRated.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('Top Rated', Uicons.star, cs),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(state.topRated, cs),
          ),
        ],
        if (state.bestSellers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(
                'Best Sellers', Uicons.arrowTrendUp, cs),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(state.bestSellers, cs),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(RecommendedProductModel item, ColorScheme cs) {
    final product = item.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: GestureDetector(
        onTap: () => context.push(AppConstants.productDetailRoute,
            extra: {'product': product, 'category': product.categoryName ?? 'All'}),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.thumbnailUrl != null
                  ? Image.network(product.thumbnailUrl!,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 72, height: 72,
                          color: cs.primary.withValues(alpha: 0.08),
                          child: Icon(Uicons.box,
                              color: cs.primary, size: 28)))
                  : Container(
                      width: 72, height: 72,
                      color: cs.primary.withValues(alpha: 0.08),
                      child: Icon(Uicons.box,
                          color: cs.primary, size: 28)),
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
                  const SizedBox(height: 4),
                  if (item.reason.isNotEmpty)
                    Row(
                      children: [
                        Icon(Uicons.autoAwesome,
                            size: 12, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(item.reason,
                              style: TextStyle(
                                  fontSize: 11, color: cs.primary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (product.rating > 0) ...[
                        Icon(Uicons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(product.rating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                        const SizedBox(width: 8),
                      ],
                      Text(product.formattedPrice,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<ProductModel> products, ColorScheme cs) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
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
                                child: Icon(Uicons.box,
                                    color: cs.primary, size: 32)))
                        : Container(
                            width: 140, height: 110,
                            color: cs.primary.withValues(alpha: 0.08),
                            child: Icon(Uicons.box,
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
}
