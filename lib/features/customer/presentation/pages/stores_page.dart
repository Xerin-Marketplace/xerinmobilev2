import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../cubit/recommendation_cubit.dart';
import '../cubit/recommendation_state.dart';
import '../../data/models/recommendation_model.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final _searchCtrl = TextEditingController();

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              final stores = state.stores;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text('Stores',
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
                  if (stores.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmpty(colorScheme),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildStoreCard(stores[index], colorScheme),
                          childCount: stores.length,
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
        child: Text('No stores available',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5))),
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store, ColorScheme cs) {
    return GestureDetector(
      onTap: () => context.read<RecommendationCubit>().loadStoreProducts(store.slug),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.bannerUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AppNetworkImage(
                  imageUrl: ApiConstants.resolveImageUrl(store.bannerUrl),
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                  placeholderIcon: Icons.store_outlined,
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: cs.surfaceContainerHighest,
                child: Icon(Icons.store_outlined, size: 40, color: cs.primary.withValues(alpha: 0.3)),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  store.logoUrl != null
                      ? ClipOval(
                          child: AppNetworkImage(
                            imageUrl: ApiConstants.resolveImageUrl(store.logoUrl),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                            placeholderIcon: Icons.store_outlined,
                          ),
                        )
                      : Icon(Icons.store_outlined, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(store.name,
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (store.isVerified)
                              Icon(Icons.verified, size: 16, color: cs.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (store.rating > 0) ...[
                              Icon(Icons.star, size: 14, color: Colors.amber[600]),
                              const SizedBox(width: 2),
                              Text(store.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                              const SizedBox(width: 8),
                            ],
                            Text('${store.totalProducts} products',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    store.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: store.isOpen ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
