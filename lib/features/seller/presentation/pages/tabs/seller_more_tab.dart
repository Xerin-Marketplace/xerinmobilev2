import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';

class SellerMoreTab extends StatelessWidget {
  const SellerMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final sections = [
      _SellerSection('Store', Uicons.shop, const Color(0xFFE91E63), AppConstants.sellerStoreRoute),
      _SellerSection('Inventory', Uicons.warehouse, const Color(0xFF607D8B), AppConstants.sellerInventoryRoute),
      _SellerSection('KYC', Uicons.shieldCheck, const Color(0xFF795548), AppConstants.sellerKycRoute),
      _SellerSection('Analytics', Uicons.chartSimple, const Color(0xFF3F51B5), AppConstants.sellerAnalyticsRoute),
      _SellerSection('Promotions', Uicons.ticket, const Color(0xFF00BCD4), AppConstants.sellerPromotionsRoute),
      _SellerSection('Reviews', Uicons.star, const Color(0xFFFFC107), AppConstants.sellerReviewsRoute),
      _SellerSection('Q&A', Uicons.circleQuestion, const Color(0xFF8BC34A), AppConstants.sellerQuestionsRoute),
      _SellerSection('Cancellations', Uicons.circleXmark, const Color(0xFFE53935), AppConstants.sellerCancellationsRoute),
      _SellerSection('Returns', Uicons.rotateLeft, const Color(0xFF03A9F4), AppConstants.sellerReturnsRoute),
      _SellerSection('Fulfillment', Uicons.shippingFast, const Color(0xFF4CAF50), AppConstants.sellerFulfillmentRoute),
      _SellerSection('Pickup Locations', Uicons.location, const Color(0xFF009688), AppConstants.sellerPickupLocationsRoute),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Text(
          'All Features',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${sections.length} sections available',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final s = sections[index];
            return GestureDetector(
              onTap: () => context.push(s.route),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        _buildLogoutCard(context, colorScheme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLogoutCard(BuildContext context, ColorScheme cs) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final name = user?.fullName ?? 'Seller';
    final email = user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Uicons.user, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty)
                      Text(email,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: cs.onSurface.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, cs),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Uicons.rightFromBracket, size: 18),
              label: const Text('Sign Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Uicons.rightFromBracket, color: Color(0xFFE53935), size: 32),
            ),
            const SizedBox(height: 20),
            Text('Sign Out?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Are you sure you want to sign out of your seller account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                context.go(AppConstants.signInRoute);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

class _SellerSection {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _SellerSection(this.title, this.icon, this.color, this.route);
}
