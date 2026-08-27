import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../cubit/admin_cubit.dart';
import '../../../data/models/admin_models.dart';

class AdminProductsTab extends StatefulWidget {
  final AdminDashboardLoaded? dashboardState;

  const AdminProductsTab({super.key, this.dashboardState});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AdminCubit>();
      if (cubit.state is! AdminProductsPendingLoaded && cubit.state is! AdminLoading) {
        cubit.loadPendingProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminCubit, AdminState>(
      buildWhen: (prev, curr) =>
          curr is AdminLoading ||
          curr is AdminProductsPendingLoaded ||
          curr is AdminError,
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminError) {
          return _errorView(colorScheme, state.message);
        }
        if (state is AdminProductsPendingLoaded) {
          return _productsList(colorScheme, isDark, state);
        }

        final dash = widget.dashboardState;
        if (dash != null && dash.products != null) {
          return _productsSummary(colorScheme, isDark, dash.products!);
        }

        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminCubit>().loadPendingProducts();
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _productsSummary(ColorScheme cs, bool isDark, AdminDashboardProductsModel products) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Products',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.read<AdminCubit>().loadPendingProducts(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Uicons.refresh, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _statCard(cs, isDark, 'Total', products.total, const Color(0xFF009688), Uicons.boxOpen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(cs, isDark, 'Approved', products.approved, const Color(0xFF4CAF50), Uicons.checkCircle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(cs, isDark, 'Pending', products.pendingReview, const Color(0xFFFF9800), Uicons.clock),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (products.pendingReview > 0)
          GestureDetector(
            onTap: () => context.read<AdminCubit>().loadPendingProducts(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Uicons.circleExclamation, size: 20, color: const Color(0xFFFF9800)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${products.pendingReview} products awaiting review',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                  Icon(Uicons.angleRight, size: 14, color: const Color(0xFFFF9800)),
                ],
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => context.push(AppConstants.adminProductsRoute),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Uicons.boxOpen, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Products',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Uicons.angleRight, size: 14, color: cs.primary),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _statCard(ColorScheme cs, bool isDark, String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsList(ColorScheme cs, bool isDark, AdminProductsPendingLoaded state) {
    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.checkCircle, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No pending products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All products have been reviewed',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        final name = product['name']?.toString() ?? 'Unknown';
        final seller = product['seller_name']?.toString() ?? 'Unknown seller';
        final price = product['price']?.toString() ?? '0';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Uicons.boxOpen, size: 20, color: Color(0xFFFF9800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      seller,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _errorView(ColorScheme cs, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<AdminCubit>().loadPendingProducts(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
