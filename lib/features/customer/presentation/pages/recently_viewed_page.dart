import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../shared/widgets/product_location_chip.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/product_model.dart';

class RecentlyViewedPage extends StatefulWidget {
  const RecentlyViewedPage({super.key});

  @override
  State<RecentlyViewedPage> createState() => _RecentlyViewedPageState();
}

class _RecentlyViewedPageState extends State<RecentlyViewedPage> {
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
              final products = state.recentlyViewed;
              if (products.isEmpty) {
                return _buildEmpty(colorScheme);
              }
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('Recently Viewed',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: colorScheme.onSurface),
                      onPressed: () => context.pop(),
                    ),
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
                        (context, index) =>
                            _buildProductCard(products[index], colorScheme),
                        childCount: products.length,
                      ),
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

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Text('No recently viewed products',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5))),
    );
  }

  Widget _buildProductCard(ProductModel product, ColorScheme cs) {
    return GestureDetector(
      onTap: () => context.push(AppConstants.productDetailRoute,
          extra: {'product': product, 'category': product.categoryName ?? 'All'}),
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
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.inventory_2_outlined,
                                color: cs.primary, size: 36)))
                    : Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.inventory_2_outlined,
                            color: cs.primary, size: 36)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.categoryName != null)
                        Expanded(
                          child: Text(
                            product.categoryName!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.primary.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (product.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (product.displayLocation != null || product.displayCountry != null) ...[
                    const SizedBox(height: 5),
                    ProductLocationChip(
                      location: product.displayLocation,
                      country: product.displayCountry,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text('Price',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.35))),
                  const SizedBox(height: 2),
                  Text(product.formattedPrice,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
