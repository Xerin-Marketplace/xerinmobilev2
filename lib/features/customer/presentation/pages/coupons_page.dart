import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/recommendation_model.dart';
import '../../../../core/theme/uicons.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
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
              final coupons = state.coupons;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('Coupons & Offers',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                    ),
                    leading: IconButton(
                      icon: Icon(Uicons.arrowBack,
                          color: colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (coupons.isEmpty)
                    SliverToBoxAdapter(child: _buildEmpty(colorScheme))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildCouponCard(coupons[index], colorScheme),
                          childCount: coupons.length,
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
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.hashtag,
                size: 72, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text('No coupons available',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Check back later for exciting offers!',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon, ColorScheme cs) {
    final isExpired = !coupon.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? cs.onSurface.withValues(alpha: 0.06)
              : cs.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpired
                      ? [cs.onSurface.withValues(alpha: 0.1), cs.onSurface.withValues(alpha: 0.05)]
                      : [cs.primary, cs.primary.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Uicons.hashtag,
                      color: isExpired ? cs.onSurface.withValues(alpha: 0.3) : Colors.white,
                      size: 28),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(coupon.code,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? cs.onSurface.withValues(alpha: 0.4)
                                    : cs.primary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? cs.onSurface.withValues(alpha: 0.06)
                                : cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(coupon.discountDisplay,
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isExpired
                                      ? cs.onSurface.withValues(alpha: 0.4)
                                      : cs.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (coupon.description.isNotEmpty)
                      Text(coupon.description,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (coupon.minOrderAmount > 0)
                          Text('Min order: TZS ${coupon.minOrderAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                        const Spacer(),
                        if (isExpired)
                          Text('Expired',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.4)))
                        else
                          Text('Available',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF22C55E))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
