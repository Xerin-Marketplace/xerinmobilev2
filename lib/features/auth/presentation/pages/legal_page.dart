import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String lastUpdated;
  final List<_LegalSection> sections;

  const LegalPage({
    super.key,
    required this.title,
    required this.icon,
    required this.lastUpdated,
    required this.sections,
  });

  factory LegalPage.termsOfService() {
    return const LegalPage(
      title: 'Terms of Service',
      icon: Icons.description_rounded,
      lastUpdated: 'July 2026',
      sections: [
        _LegalSection(
          icon: Icons.handshake_rounded,
          title: '1. Acceptance of Terms',
          body: 'By creating an account and using XerinMarket, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you should not use our platform. Your continued use of the app constitutes acceptance of any updates.',
        ),
        _LegalSection(
          icon: Icons.person_rounded,
          title: '2. User Accounts',
          body: 'You must provide accurate and complete information when registering. You are responsible for maintaining the security of your account and password. XerinMarket cannot be liable for any losses caused by unauthorized access to your account.',
        ),
        _LegalSection(
          icon: Icons.store_rounded,
          title: '3. Seller Responsibilities',
          body: 'Sellers must provide accurate product descriptions, fair pricing, and timely delivery. Sellers are responsible for the quality and legality of their products. XerinMarket reserves the right to suspend sellers who violate these terms.',
        ),
        _LegalSection(
          icon: Icons.shopping_bag_rounded,
          title: '4. Purchases & Payments',
          body: 'All purchases made through XerinMarket are subject to product availability. Prices are listed in TZS and may change without notice. Payments are processed securely through our approved payment partners.',
        ),
        _LegalSection(
          icon: Icons.undo_rounded,
          title: '5. Returns & Refunds',
          body: 'Customers may request returns within 7 days of delivery for defective or incorrect items. Refunds are processed to the original payment method within 5-10 business days. Certain items may be non-refundable.',
        ),
        _LegalSection(
          icon: Icons.gavel_rounded,
          title: '6. Prohibited Conduct',
          body: 'Users must not use the platform for illegal activities, fraud, harassment, or selling prohibited items. Violations may result in account termination and legal action.',
        ),
        _LegalSection(
          icon: Icons.shield_rounded,
          title: '7. Limitation of Liability',
          body: 'XerinMarket provides a marketplace platform and is not directly responsible for transactions between buyers and sellers. We are not liable for indirect, incidental, or consequential damages arising from platform use.',
        ),
        _LegalSection(
          icon: Icons.update_rounded,
          title: '8. Changes to Terms',
          body: 'We may update these Terms of Service at any time. Continued use after changes constitutes acceptance of the new terms. We will notify users of significant changes through the app.',
        ),
      ],
    );
  }

  factory LegalPage.privacyPolicy() {
    return const LegalPage(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_rounded,
      lastUpdated: 'July 2026',
      sections: [
        _LegalSection(
          icon: Icons.info_rounded,
          title: '1. Information We Collect',
          body: 'We collect your name, email, phone number, delivery addresses, and payment information when you register and use XerinMarket. We also collect usage data such as search history and app interactions to improve your experience.',
        ),
        _LegalSection(
          icon: Icons.lock_rounded,
          title: '2. How We Use Your Data',
          body: 'Your information is used to process orders, deliver products, communicate updates, verify identity, and improve our services. We do not sell your personal data to third parties.',
        ),
        _LegalSection(
          icon: Icons.share_rounded,
          title: '3. Information Sharing',
          body: 'We share necessary information with sellers (for order fulfillment), payment processors (for transactions), and delivery partners (for shipping). All sharing is done securely and only with authorized parties.',
        ),
        _LegalSection(
          icon: Icons.security_rounded,
          title: '4. Data Security',
          body: 'We use industry-standard encryption and security measures to protect your data. Access to personal information is restricted to authorized personnel only. However, no method of transmission over the internet is 100% secure.',
        ),
        _LegalSection(
          icon: Icons.cookie_rounded,
          title: '5. Cookies & Tracking',
          body: 'XerinMarket uses local storage and cookies to remember your preferences, keep you logged in, and analyze app usage. You can disable cookies in your device settings, but some features may not work properly.',
        ),
        _LegalSection(
          icon: Icons.edit_rounded,
          title: '6. Your Rights',
          body: 'You have the right to access, update, or delete your personal information. You can also opt out of marketing communications. To exercise these rights, contact us through the app settings.',
        ),
        _LegalSection(
          icon: Icons.child_care_rounded,
          title: '7. Children\'s Privacy',
          body: 'XerinMarket is not intended for users under 18 years old. We do not knowingly collect data from minors. If you believe a child has registered, please contact us for immediate account removal.',
        ),
        _LegalSection(
          icon: Icons.update_rounded,
          title: '8. Policy Updates',
          body: 'This Privacy Policy may be updated periodically. We will notify you of significant changes through the app. Your continued use after updates means you accept the revised policy.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colorScheme, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...sections.map((section) => _buildSection(
                          section,
                          colorScheme,
                          isDark,
                        )),
                    const SizedBox(height: 24),
                    _buildContactCard(colorScheme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
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
                onTap: () => context.canPop() ? context.pop() : context.go('/register'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last updated: $lastUpdated',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    _LegalSection section,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.8),
                      colorScheme.primary.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(section.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              section.body,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Contact us at support@xerin.co.tz',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final IconData icon;
  final String title;
  final String body;

  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
  });
}
