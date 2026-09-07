import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

class BrokerMoreTab extends StatelessWidget {
  const BrokerMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = [
      _BrokerSection('KYC', Uicons.shieldCheck, const Color(0xFF795548), AppConstants.brokerKycRoute),
      _BrokerSection('Wallet', Uicons.wallet, const Color(0xFF4CAF50), AppConstants.brokerWalletRoute),
      _BrokerSection('Earnings', Uicons.sackDollar, const Color(0xFFFFC107), AppConstants.brokerEarningsRoute),
      _BrokerSection('Analytics', Uicons.chartPie, const Color(0xFF3F51B5), AppConstants.brokerAnalyticsRoute),
      _BrokerSection('Opportunities', Uicons.barChart, const Color(0xFF00BCD4), AppConstants.brokerOpportunitiesRoute),
      _BrokerSection('Find Products', Uicons.search, const Color(0xFFE91E63), AppConstants.mawingaFindProductsRoute),
      _BrokerSection('Share & Earn', Uicons.share, const Color(0xFF8BC34A), AppConstants.mawingaShareEarnRoute),
      _BrokerSection('Leaderboard', Uicons.trophy, const Color(0xFFD97706), AppConstants.mawingaLeaderboardRoute),
      _BrokerSection('Academy', Uicons.book, const Color(0xFF607D8B), AppConstants.mawingaAcademyRoute),
      _BrokerSection('My Store', Uicons.shop, const Color(0xFF009688), AppConstants.mawingaStoreRoute),
      _BrokerSection('Invite', Uicons.user, const Color(0xFF03A9F4), AppConstants.mawingaReferralRoute),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('All Features',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('${sections.length} sections available',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82,
          ),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final s = sections[index];
            return GestureDetector(
              onTap: () => context.push(s.route),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(s.title,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BrokerSection {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _BrokerSection(this.title, this.icon, this.color, this.route);
}
