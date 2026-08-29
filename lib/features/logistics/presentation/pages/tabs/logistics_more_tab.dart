import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';

class LogisticsMoreTab extends StatelessWidget {
  const LogisticsMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final sections = [
      _LogisticsSection('Wallet', Uicons.wallet, const Color(0xFF4CAF50), AppConstants.logisticsWalletRoute),
      _LogisticsSection('Team', Uicons.users, const Color(0xFF2196F3), AppConstants.logisticsTeamRoute),
      _LogisticsSection('Pricing', Uicons.tags, const Color(0xFFFF9800), AppConstants.logisticsPricingRoute),
      _LogisticsSection('Integration', Uicons.bolt, const Color(0xFF9C27B0), AppConstants.logisticsIntegrationRoute),
      _LogisticsSection('Onboarding', Uicons.rocket, const Color(0xFF00BCD4), AppConstants.logisticsOnboardingRoute),
      _LogisticsSection('Settings', Uicons.settings, const Color(0xFF607D8B), AppConstants.logisticsSettingsRoute),
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
      ],
    );
  }
}

class _LogisticsSection {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _LogisticsSection(this.title, this.icon, this.color, this.route);
}
