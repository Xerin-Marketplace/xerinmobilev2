import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final menuItems = [
      {
        'icon': Icons.verified_user_outlined,
        'label': 'KYC Verification',
        'route': AppConstants.sellerKycRoute,
      },
      {
        'icon': Icons.store_outlined,
        'label': 'Shop Details',
        'route': AppConstants.sellerShopDetailsRoute,
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Shipping Options',
        'route': AppConstants.sellerShippingOptionsRoute,
      },
      {
        'icon': Icons.payment_outlined,
        'label': 'Payouts',
        'route': AppConstants.sellerPayoutsRoute,
      },
      {
        'icon': Icons.bar_chart_outlined,
        'label': 'Reports',
        'route': AppConstants.sellerReportsRoute,
      },
      {
        'icon': Icons.support_agent_outlined,
        'label': 'Seller Support',
        'route': AppConstants.sellerSupportRoute,
      },
      {
        'icon': Icons.logout_rounded,
        'label': 'Logout',
        'color': const Color(0xFFE53935),
      },
    ];

    return SafeArea(
      child: BlocBuilder<SellerCubit, SellerState>(
        builder: (context, state) {
          if (state is SellerDashboardLoaded) {
            final profile = state.profile;
            final store = state.store;
            final kycStatus = state.kycStatus;
            final payouts = state.payoutAccounts;

            final storeName = store?.storeName ?? profile?.businessName ?? 'Seller';
            final email = profile?.contactEmail ?? store?.contactEmail ?? 'N/A';
            final rating = store?.rating ?? 0.0;
            final reviewCount = store?.reviewCount ?? 0;
            final followers = store?.followersCount ?? 0;
            final isVerified = store?.isVerified ?? false;
            final sellerStatus = profile?.status ?? kycStatus?.sellerStatus ?? 'pending';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: store?.logoUrl != null && store!.logoUrl!.isNotEmpty
                                ? Image.network(
                                    store.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.store_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  )
                                : const Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Colors.white, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(sellerStatus).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Status: ${sellerStatus.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(sellerStatus),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatBadge(rating.toStringAsFixed(1), 'Rating'),
                            const SizedBox(width: 12),
                            _buildStatBadge('$reviewCount', 'Reviews'),
                            const SizedBox(width: 12),
                            _buildStatBadge('$followers', 'Followers'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (payouts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: colorScheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payout Accounts',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  '${payouts.length} account(s) linked',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppConstants.sellerPayoutsRoute),
                            child: Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: menuItems.map((item) {
                        final color = item['color'] as Color? ?? colorScheme.onSurface;
                        return ListTile(
                          leading: Icon(
                            item['icon'] as IconData,
                            color: color.withValues(alpha: 0.7),
                            size: 22,
                          ),
                          title: Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onTap: () {
                            final route = item['route'] as String?;
                            if (route != null) {
                              context.go(route);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          if (state is SellerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF22C55E);
      case 'pending':
      case 'under_review':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
