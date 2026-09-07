import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/uicons.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;

  const LegalPage({
    super.key,
    required this.title,
    required this.icon,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  factory LegalPage.termsOfService() {
    return const LegalPage(
      title: 'Terms of Service',
      icon: Uicons.description,
      lastUpdated: 'September 2026',
      intro:
          'Welcome to XerinMarket. These Terms of Service govern your use of our marketplace platform. By registering an account or using our app, you enter into a legally binding agreement with us. Please read carefully.',
      sections: [
        LegalSection(
          icon: Uicons.handshake,
          title: '1. Acceptance of Terms',
          body: 'By creating an account, browsing products, or completing any transaction on XerinMarket, you agree to be bound by these Terms. If you do not agree, you must stop using the platform immediately. Your continued use after any update constitutes acceptance of the revised terms.',
          bullets: [
            'Registration implies full acceptance of all terms',
            'Terms apply to all user roles: buyers, sellers, brokers, and logistics partners',
            'Minors under 18 may not register or transact',
          ],
        ),
        LegalSection(
          icon: Uicons.user,
          title: '2. Account Registration & Security',
          body: 'You must provide truthful, accurate, and current information during registration. You are solely responsible for safeguarding your account credentials and for all activity under your account.',
          bullets: [
            'Use a strong, unique password and enable PIN lock',
            'Notify us immediately of any unauthorized access',
            'One person may not operate multiple buyer accounts',
            'Phone numbers must be verified via OTP',
          ],
        ),
        LegalSection(
          icon: Uicons.shop,
          title: '3. Seller Responsibilities',
          body: 'Sellers are independent businesses using XerinMarket as a sales channel. Sellers bear full responsibility for product quality, legality, listing accuracy, and fulfillment.',
          bullets: [
            'Product images must match the actual item delivered',
            'Prices must be clearly stated in TZS and inclusive of all applicable taxes',
            'Sellers must fulfill orders within stated handling times',
            'Prohibited products include: alcohol, tobacco, weapons, counterfeit goods, and regulated pharmaceuticals',
            'XerinMarket reserves the right to delist products or suspend seller accounts for violations',
          ],
        ),
        LegalSection(
          icon: Uicons.shoppingBag,
          title: '4. Purchases, Pricing & Payments',
          body: 'All purchases are subject to product availability. While we strive for accurate pricing, errors may occur. We reserve the right to cancel orders affected by pricing errors with a full refund.',
          bullets: [
            'Prices are displayed in TZS and may be converted for display only',
            'Backend revalidation occurs before checkout to confirm price and stock',
            'Payments are processed through licensed payment partners (mobile money, cards, bank transfers)',
            'XerinMarket charges a platform commission on each completed sale, separate from seller-set prices',
          ],
        ),
        LegalSection(
          icon: Uicons.truckBox,
          title: '5. Shipping, Delivery & Logistics',
          body: 'Delivery is handled by XerinMarket logistics partners. Estimated delivery times are provided at checkout but are not guaranteed. Risk of loss passes to the buyer upon confirmed delivery.',
          bullets: [
            'Delivery protection covers lost or damaged items in transit',
            'Buyers must verify package contents at delivery when possible',
            'Delivery address changes after dispatch are not guaranteed',
          ],
        ),
        LegalSection(
          icon: Uicons.rotateLeft,
          title: '6. Returns, Refunds & Disputes',
          body: 'We aim for fair resolution of all disputes. Buyers may request returns within 7 days of delivery for defective, damaged, or incorrect items.',
          bullets: [
            'Refunds are processed to the original payment method within 5-10 business days',
            'Certain items are non-refundable: perishables, personal care items, and custom orders',
            'Disputes must be filed through the in-app support system within 14 days',
            'XerinMarket mediates disputes but is not a party to buyer-seller transactions',
          ],
        ),
        LegalSection(
          icon: Uicons.gavel,
          title: '7. Prohibited Conduct',
          body: 'Users must not engage in any activity that harms the platform, other users, or third parties. Violations may result in immediate account termination and legal action.',
          bullets: [
            'No fraudulent transactions, chargeback abuse, or payment manipulation',
            'No harassment, hate speech, or discriminatory behavior',
            'No scraping, reverse engineering, or automated access to the platform',
            'No selling of stolen, counterfeit, or illegal goods',
            'No manipulation of reviews, ratings, or search rankings',
          ],
        ),
        LegalSection(
          icon: Uicons.ban,
          title: '8. Account Suspension & Termination',
          body: 'XerinMarket may suspend or terminate any account that violates these Terms. We may also terminate accounts for inactivity exceeding 24 months.',
          bullets: [
            'Suspended users may appeal through the support system',
            'Terminated sellers receive pending payouts within 30 days',
            'XerinMarket is not liable for business losses resulting from account termination',
          ],
        ),
        LegalSection(
          icon: Uicons.shield,
          title: '9. Limitation of Liability',
          body: 'XerinMarket is a marketplace platform that connects buyers and sellers. We are not a party to transactions between users and bear no responsibility for product quality, seller performance, or delivery outcomes beyond our platform fee.',
          bullets: [
            'We are not liable for indirect, incidental, or consequential damages',
            'Total liability is limited to the platform fee earned on the relevant transaction',
            'We do not guarantee uninterrupted access to the platform',
          ],
        ),
        LegalSection(
          icon: Uicons.globe,
          title: '10. Governing Law',
          body: 'These Terms are governed by the laws of the United Republic of Tanzania. Any disputes shall be resolved in the courts of Tanzania unless otherwise agreed in writing.',
        ),
        LegalSection(
          icon: Uicons.refresh,
          title: '11. Changes to Terms',
          body: 'We may update these Terms at any time. Significant changes will be notified through the app. Continued use after the effective date constitutes acceptance of the updated Terms.',
        ),
      ],
    );
  }

  factory LegalPage.privacyPolicy() {
    return const LegalPage(
      title: 'Privacy Policy',
      icon: Uicons.shield,
      lastUpdated: 'September 2026',
      intro:
          'Your privacy matters to us. This Privacy Policy explains what personal data XerinMarket collects, how we use it, who we share it with, and the rights you have over your data. We are committed to protecting your information in accordance with Tanzanian data protection standards.',
      sections: [
        LegalSection(
          icon: Uicons.circleInfo,
          title: '1. Information We Collect',
          body: 'We collect information you provide directly and data generated automatically when you use our platform.',
          bullets: [
            'Account data: name, email, phone number, password (hashed)',
            'Profile data: delivery addresses, profile photo, preferred currency',
            'Transaction data: order history, payment method references, invoices',
            'Usage data: search queries, product views, app interactions, device info',
            'Location data: approximate location for delivery and logistics (with permission)',
          ],
        ),
        LegalSection(
          icon: Uicons.lock,
          title: '2. How We Use Your Data',
          body: 'We process your data to provide and improve our services. We never sell your personal data to any third party.',
          bullets: [
            'Process orders, payments, and deliveries',
            'Verify identity and prevent fraud',
            'Send order updates, notifications, and customer support messages',
            'Personalize product recommendations and search results',
            'Improve app performance, fix bugs, and develop new features',
            'Comply with legal obligations and law enforcement requests',
          ],
        ),
        LegalSection(
          icon: Uicons.share,
          title: '3. Information Sharing',
          body: 'We share only the minimum necessary data with trusted partners to operate the marketplace. All partners are bound by confidentiality obligations.',
          bullets: [
            'Sellers receive buyer name, phone, and delivery address for order fulfillment',
            'Payment processors receive transaction details (no full card numbers are stored)',
            'Logistics partners receive delivery address and contact information',
            'Regulatory authorities may receive data upon valid legal request',
          ],
        ),
        LegalSection(
          icon: Uicons.shieldCheck,
          title: '4. Data Security',
          body: 'We implement industry-standard security measures to protect your data from unauthorized access, alteration, or disclosure.',
          bullets: [
            'All data in transit is encrypted via TLS/SSL',
            'Passwords are hashed using bcrypt — never stored in plain text',
            'Payment tokens are handled by certified PCI-DSS compliant processors',
            'Access to personal data is restricted to authorized personnel on a need-to-know basis',
            'Regular security audits and vulnerability assessments are conducted',
          ],
        ),
        LegalSection(
          icon: Uicons.cookie,
          title: '5. Cookies & Local Storage',
          body: 'XerinMarket uses local storage and device identifiers to keep you logged in, remember preferences, and analyze app usage.',
          bullets: [
            'Authentication tokens keep you signed in securely',
            'Theme and currency preferences are stored locally',
            'Analytics help us understand feature usage and improve the app',
            'You can clear local data anytime from your device settings',
          ],
        ),
        LegalSection(
          icon: Uicons.edit,
          title: '6. Your Rights',
          body: 'You have full control over your personal data. Tanzanian data protection law grants you the following rights:',
          bullets: [
            'Right to access: request a copy of your personal data',
            'Right to rectification: correct inaccurate or incomplete data',
            'Right to erasure: request deletion of your account and associated data',
            'Right to restrict processing: limit how we use your data',
            'Right to data portability: receive your data in a structured format',
            'Right to object: opt out of marketing communications at any time',
          ],
        ),
        LegalSection(
          icon: Uicons.clock,
          title: '7. Data Retention',
          body: 'We retain your data only as long as necessary for the purposes described in this policy.',
          bullets: [
            'Active accounts: data is retained while the account is active',
            'Closed accounts: personal data is deleted within 90 days, except where legal retention is required',
            'Transaction records: retained for 7 years per Tanzanian tax law',
            'Support tickets: retained for 2 years for quality and dispute resolution',
          ],
        ),
        LegalSection(
          icon: Uicons.child,
          title: '8. Children\'s Privacy',
          body: 'XerinMarket is not directed at children under 18. We do not knowingly collect data from minors. If you believe a child has registered, contact us immediately for account removal and data deletion.',
        ),
        LegalSection(
          icon: Uicons.userShield,
          title: '9. Broker & Partner Data',
          body: 'Brokers and logistics partners who use XerinMarket agree to handle all buyer and seller data in compliance with this Privacy Policy and Tanzanian data protection law.',
          bullets: [
            'Partners may not use shared data for purposes outside XerinMarket',
            'Partners must delete shared data when the business relationship ends',
            'Violations result in immediate partnership termination',
          ],
        ),
        LegalSection(
          icon: Uicons.refresh,
          title: '10. Policy Updates',
          body: 'This Privacy Policy may be updated periodically. We will notify you of significant changes through in-app notifications. Your continued use after the effective date means you accept the revised policy.',
        ),
      ],
    );
  }

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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildIntroCard(cs, isDark),
                    const SizedBox(height: 20),
                    ...sections.map((s) => _buildSection(s, cs, isDark)),
                    const SizedBox(height: 12),
                    _buildContactCard(cs, isDark),
                    const SizedBox(height: 16),
                    _buildFooter(cs),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Uicons.clock, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 5),
                Text(
                  'Updated $lastUpdated',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Uicons.circleInfo, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Overview',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            intro,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(LegalSection section, ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(section.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                section.body,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.65,
                ),
              ),
              if (section.bullets != null && section.bullets!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...section.bullets!.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.55),
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text('Questions about this document?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text('Our team is here to help you',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ContactChip(icon: Uicons.envelope, label: 'support@xerin.co.tz', cs: cs),
              const SizedBox(width: 8),
              _ContactChip(icon: Uicons.phone, label: '+255 700 000 000', cs: cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Center(
      child: Column(
        children: [
          Text('XerinMarket — Dar es Salaam, Tanzania',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 4),
          Text('© 2026 XerinMarket. All rights reserved.',
            style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _ContactChip({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  final IconData icon;
  final String title;
  final String body;
  final List<String>? bullets;

  const LegalSection({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets,
  });
}
