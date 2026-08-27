import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../cubit/admin_cubit.dart';
import '../../../data/models/admin_models.dart';

class AdminSellersTab extends StatefulWidget {
  final AdminDashboardLoaded? dashboardState;

  const AdminSellersTab({super.key, this.dashboardState});

  @override
  State<AdminSellersTab> createState() => _AdminSellersTabState();
}

class _AdminSellersTabState extends State<AdminSellersTab> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AdminCubit>();
      if (cubit.state is! AdminSellersLoaded && cubit.state is! AdminLoading) {
        cubit.loadSellers();
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
          curr is AdminSellersLoaded ||
          curr is AdminError,
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminError) {
          return _errorView(colorScheme, state.message);
        }
        if (state is AdminSellersLoaded) {
          return _sellersList(colorScheme, isDark, state);
        }

        final dash = widget.dashboardState;
        if (dash != null && dash.sellers != null) {
          return _sellersSummary(colorScheme, isDark, dash.sellers!);
        }

        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminCubit>().loadSellers();
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _sellersSummary(ColorScheme cs, bool isDark, AdminDashboardSellersModel sellers) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sellers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.read<AdminCubit>().loadSellers(),
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
                      'Load All',
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
              child: _statCard(cs, isDark, 'Total', sellers.total, const Color(0xFFFF9800), Uicons.storeAlt),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(cs, isDark, 'Approved', sellers.approved, const Color(0xFF4CAF50), Uicons.checkCircle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(cs, isDark, 'Pending', sellers.pending, const Color(0xFFE53935), Uicons.clock),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.push(AppConstants.adminSellersRoute),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Uicons.storeAlt, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Manage Sellers',
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

  Widget _sellersList(ColorScheme cs, bool isDark, AdminSellersLoaded state) {
    if (state.sellers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.storeAlt, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No sellers found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.sellers.length,
      itemBuilder: (context, index) {
        final seller = state.sellers[index];
        final statusColor = seller.status == 'approved'
            ? const Color(0xFF4CAF50)
            : seller.status == 'pending'
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935);

        return GestureDetector(
          onTap: () => context.push(AppConstants.adminSellerDetailRoute, extra: {'seller': seller}),
          child: Container(
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Uicons.storeAlt, size: 20, color: statusColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.businessName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        seller.contactEmail ?? 'No email',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    seller.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
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
            onPressed: () => context.read<AdminCubit>().loadSellers(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
