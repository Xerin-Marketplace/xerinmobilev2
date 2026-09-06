import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../shared/widgets/guest_auth_gate.dart';
import '../../../data/models/wishlist_item_model.dart';
import '../../cubit/wishlist_cubit.dart';
import '../../cubit/wishlist_state.dart';

class CustomerWishlistPage extends StatefulWidget {
  const CustomerWishlistPage({super.key});

  @override
  State<CustomerWishlistPage> createState() => _CustomerWishlistPageState();
}

class _CustomerWishlistPageState extends State<CustomerWishlistPage> {
  late final WishlistCubit _wishlistCubit;

  @override
  void initState() {
    super.initState();
    _wishlistCubit = sl<WishlistCubit>()..loadWishlist();
  }

  @override
  void dispose() {
    _wishlistCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (GuestAuthGate.isGuest) {
      return GuestAuthGate(
        title: 'Sign In to View Wishlist',
        message: 'Save items you love. Sign in to access your wishlist and never lose track of your favorites.',
        child: const SizedBox.shrink(),
      );
    }

    return BlocProvider.value(
      value: _wishlistCubit,
      child: BlocBuilder<WishlistCubit, WishlistState>(
        builder: (context, state) {
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(colorScheme, state),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: _buildBody(colorScheme, state, isDark),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, WishlistState state) {
    final items = state is WishlistLoaded ? state.items : <WishlistItemModel>[];
    final selected = state is WishlistLoaded ? state.selectedIds : <String>{};
    final count = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              size: 22,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wishlist',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    count == 1 ? '1 saved item' : '$count saved items',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => _wishlistCubit.loadWishlist(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (count > 0) ...[
          Row(
            children: [
              _buildActionChip(
                colorScheme,
                icon: Icons.checklist,
                label: selected.isEmpty ? 'Select all' : 'Clear',
                onTap: () {
                  if (selected.isEmpty) {
                    context.read<WishlistCubit>().selectAll();
                  } else {
                    context.read<WishlistCubit>().clearSelection();
                  }
                },
              ),
              const SizedBox(width: 10),
              if (selected.isNotEmpty)
                _buildActionChip(
                  colorScheme,
                  icon: Icons.delete_outline,
                  label: 'Delete (${selected.length})',
                  isDestructive: true,
                  onTap: () => context.read<WishlistCubit>().removeSelected(),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildActionChip(
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDestructive ? const Color(0xFFE53935) : colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDestructive ? const Color(0xFFE53935) : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, WishlistState state, bool isDark) {
    if (state is WishlistLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (state is WishlistError) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 36,
                  color: const Color(0xFFE53935).withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load wishlist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.message.replaceAll('ServerException: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.read<WishlistCubit>().loadWishlist(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is WishlistLoaded && state.items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your wishlist is empty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on products\nto save them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Browse Products'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is WishlistLoaded) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = state.items[index];
            final isSelected = state.selectedIds.contains(item.id);
            return _buildWishlistCard(context, colorScheme, item, isSelected, isDark);
          },
          childCount: state.items.length,
        ),
      );
    }

    return const SliverFillRemaining(child: SizedBox.shrink());
  }

  Widget _buildWishlistCard(
    BuildContext context,
    ColorScheme colorScheme,
    WishlistItemModel item,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.go(
        AppConstants.productDetailRoute,
        extra: {
          'product': item.toProductModel(),
          'category': item.categoryName ?? 'All',
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
                          )
                        : _buildPlaceholder(colorScheme),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => context.read<WishlistCubit>().toggleSelection(item.id),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 24,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => context.read<WishlistCubit>().removeItem(item.id),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  if (item.hasDiscount)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        '-${item.discountPercent}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                  if (!item.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: Text(
                            'Out of stock',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.storeName != null) ...[
                    Text(
                      item.storeName!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.hasDiscount) ...[
                        Text(
                          item.formattedSalePrice!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.formattedPrice,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          item.formattedPrice,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
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

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
