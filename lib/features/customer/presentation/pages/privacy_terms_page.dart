import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';

class PrivacyTermsPage extends StatelessWidget {
  const PrivacyTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cs),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Legal documents and policies for XerinMarket.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4), height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    _MenuCard(
                      icon: Uicons.shield,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Privacy Policy',
                      subtitle: 'How we collect, use, and protect your data',
                      onTap: () => context.push(AppConstants.privacyRoute),
                    ),
                    const SizedBox(height: 10),

                    _MenuCard(
                      icon: Uicons.description,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Terms & Conditions',
                      subtitle: 'Rules and guidelines for using XerinMarket',
                      onTap: () => context.push(AppConstants.termsRoute),
                    ),
                    const SizedBox(height: 24),

                    _buildTrustBadges(cs, isDark),
                    const SizedBox(height: 20),

                    _buildContactCard(cs, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : context.go('/'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Uicons.arrowBack, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Uicons.shieldCheck, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Uicons.shieldCheck, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Privacy & Terms',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text('Your rights and our responsibilities',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges(ColorScheme cs, bool isDark) {
    final badges = [
      _TrustBadge(icon: Uicons.lock, label: 'Data encrypted'),
      _TrustBadge(icon: Uicons.shieldCheck, label: 'PCI-DSS compliant'),
      _TrustBadge(icon: Uicons.globe, label: 'Tanzanian law'),
    ];
    return Row(
      children: badges.map((b) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Icon(b.icon, size: 20, color: cs.primary),
              const SizedBox(height: 6),
              Text(b.label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildContactCard(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Uicons.headset, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Questions?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text('Contact us at support@xerin.co.tz',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: cs.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
