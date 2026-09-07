import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../data/models/broker_models.dart';
import '../../../data/models/mawinga_models.dart';
import '../../cubit/broker_cubit.dart';

const _mawingaPrimary = Color(0xFF6D28D9);
const _mawingaLight = Color(0xFF8B5CF6);

class BrokerHomeTab extends StatelessWidget {
  final BrokerDashboardLoaded state;
  final VoidCallback onRefresh;

  const BrokerHomeTab({super.key, required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final broker = state.broker;
    final analytics = state.analytics;
    final approved = broker.isApproved;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _welcomeCard(cs, broker),
        if (!approved) ...[const SizedBox(height: 16), _kycBanner(cs, broker)],
        if (approved && analytics != null) ...[const SizedBox(height: 16), _levelCard(cs, analytics)],
        const SizedBox(height: 20),
        _sectionTitle('Quick actions', cs),
        const SizedBox(height: 10),
        _quickActions(cs, approved),
        if (approved && analytics != null) ...[
          const SizedBox(height: 20),
          _sectionTitle('Performance', cs),
          const SizedBox(height: 10),
          _metricsGrid(cs, analytics),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _welcomeCard(ColorScheme cs, broker) {
    final statusLabels = {
      'pending_kyc': 'Complete KYC', 'kyc_submitted': 'KYC Submitted',
      'under_review': 'Under Review', 'approved': 'Approved',
      'rejected': 'Action Required', 'suspended': 'Suspended',
    };
    final statusLabel = statusLabels[broker.status] ?? broker.status;
    final statusColor = broker.isApproved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_mawingaPrimary, _mawingaLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _mawingaPrimary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back, ${broker.firstName ?? 'Mawinga'}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Mawinga ID: ${broker.brokerCode}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(broker.isApproved ? Uicons.circleCheck : Uicons.circleInfo, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(statusLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }

  Widget _kycBanner(ColorScheme cs, broker) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Uicons.shieldCheck, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text('Complete identity verification to activate your account.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface))),
        ]),
        const SizedBox(height: 8),
        Text('Products, earnings and wallet stay locked until your KYC is approved.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5), height: 1.4)),
        if (broker.statusReason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Text(broker.statusReason!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => context.push(AppConstants.brokerKycRoute),
          icon: const Icon(Uicons.shieldCheck, size: 16),
          label: const Text('Open KYC Verification'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
    );
  }

  Widget _levelCard(ColorScheme cs, BrokerAnalyticsOverviewModel analytics) {
    final totalSales = analytics.successfulSales;
    final currentLevel = MawingaLevel.getLevelForSales(totalSales);
    final nextLevel = MawingaLevel.getNextLevel(currentLevel);
    final isMaxLevel = currentLevel.name == nextLevel.name;
    final salesInLevel = totalSales - currentLevel.minSales;
    final salesNeeded = isMaxLevel ? 0 : nextLevel.minSales - totalSales;
    final levelRange = currentLevel.maxSales - currentLevel.minSales + 1;
    final progress = isMaxLevel ? 1.0 : (salesInLevel / levelRange).clamp(0.0, 1.0);

    final levelColors = {
      'Starter': const Color(0xFF9CA3AF), 'Bronze': const Color(0xFFB45309),
      'Silver': const Color(0xFF64748B), 'Gold': const Color(0xFFD97706),
      'Platinum': const Color(0xFF7C3AED),
    };
    final levelColor = levelColors[currentLevel.name] ?? _mawingaPrimary;
    final levelIcons = {
      'Platinum': Uicons.star, 'Gold': Uicons.crown, 'Silver': Uicons.trophy,
      'Bronze': Uicons.medal, 'Starter': Uicons.seedling,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: levelColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(levelIcons[currentLevel.name] ?? Uicons.seedling, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${currentLevel.name} Mawinga',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text('$totalSales total sales',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ])),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress, minHeight: 7,
            backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(levelColor),
          ),
        ),
        const SizedBox(height: 8),
        if (!isMaxLevel)
          Text('You need $salesNeeded more sales to reach ${nextLevel.name}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)))
        else
          Text('Maximum level reached! You are a top Mawinga.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: levelColor)),
      ]),
    );
  }

  Widget _quickActions(ColorScheme cs, bool approved) {
    final actions = [
      {'title': 'KYC', 'desc': approved ? 'Verified' : 'Verify', 'icon': Uicons.shieldCheck, 'route': AppConstants.brokerKycRoute},
      {'title': 'Wallet', 'desc': 'Balance & payouts', 'icon': Uicons.wallet, 'route': AppConstants.brokerWalletRoute},
      {'title': 'Find Products', 'desc': 'Browse & sell', 'icon': Uicons.search, 'route': AppConstants.mawingaFindProductsRoute},
      {'title': 'Share & Earn', 'desc': 'Share products', 'icon': Uicons.share, 'route': AppConstants.mawingaShareEarnRoute},
      {'title': 'My Products', 'desc': 'Your listings', 'icon': Uicons.box, 'route': AppConstants.brokerProductsRoute},
      {'title': 'Opportunities', 'desc': 'Browse campaigns', 'icon': Uicons.barChart, 'route': AppConstants.brokerOpportunitiesRoute},
      {'title': 'Earnings', 'desc': 'Commission', 'icon': Uicons.sackDollar, 'route': AppConstants.brokerEarningsRoute},
      {'title': 'Analytics', 'desc': 'Performance', 'icon': Uicons.chartPie, 'route': AppConstants.brokerAnalyticsRoute},
      {'title': 'Leaderboard', 'desc': 'Top Mawinga', 'icon': Uicons.trophy, 'route': AppConstants.mawingaLeaderboardRoute},
      {'title': 'Academy', 'desc': 'Learn & grow', 'icon': Uicons.book, 'route': AppConstants.mawingaAcademyRoute},
      {'title': 'My Store', 'desc': 'Digital store', 'icon': Uicons.shop, 'route': AppConstants.mawingaStoreRoute},
      {'title': 'Invite', 'desc': 'Refer & earn', 'icon': Uicons.user, 'route': AppConstants.mawingaReferralRoute},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        final isLocked = !approved && a['title'] != 'KYC';
        return GestureDetector(
          onTap: isLocked ? null : () => context.push(a['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLocked ? cs.onSurface.withValues(alpha: 0.03) : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLocked ? cs.onSurface.withValues(alpha: 0.06) : _mawingaPrimary.withValues(alpha: 0.12),
              ),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(clipBehavior: Clip.none, children: [
                Icon(a['icon'] as IconData, size: 24,
                    color: isLocked ? cs.onSurface.withValues(alpha: 0.25) : _mawingaPrimary),
                if (isLocked)
                  Positioned(bottom: -2, right: -4,
                    child: Icon(Uicons.lock, size: 10, color: cs.onSurface.withValues(alpha: 0.3))),
              ]),
              const SizedBox(height: 8),
              Text(a['title'] as String,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: isLocked ? cs.onSurface.withValues(alpha: 0.35) : cs.onSurface),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(a['desc'] as String,
                  style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.35)),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }

  Widget _metricsGrid(ColorScheme cs, BrokerAnalyticsOverviewModel analytics) {
    final metrics = [
      ('Referral Clicks', analytics.totalClicks.toString(), '${analytics.uniqueVisitors} unique'),
      ('Attributed Orders', analytics.attributedOrders.toString(), '${analytics.conversionRate}% conversion'),
      ('Available Earnings', analytics.availableEarnings, '${analytics.pendingEarnings} pending'),
      ('Wallet', analytics.walletAvailable, '${analytics.walletPaidOut} paid out'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5,
      children: metrics.map((m) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(m.$2, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface))),
            const SizedBox(height: 2),
            Text(m.$3, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4))),
          ]),
        );
      }).toList(),
    );
  }
}
