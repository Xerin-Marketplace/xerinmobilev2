import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/broker_models.dart';
import '../../data/models/mawinga_models.dart';
import '../cubit/broker_cubit.dart';

class BrokerDashboardPage extends StatefulWidget {
  const BrokerDashboardPage({super.key});

  @override
  State<BrokerDashboardPage> createState() => _BrokerDashboardPageState();
}

class _BrokerDashboardPageState extends State<BrokerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mawinga Hub'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () =>
                context.read<BrokerCubit>().loadDashboard(refresh: true),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showAccountSheet(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Uicons.user,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<BrokerCubit>().loadDashboard(refresh: true),
              child: _buildDashboard(context, state, colorScheme),
            );
          }
          if (state is BrokerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BrokerCubit>().loadDashboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAccountSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = GetIt.instance<TokenStorage>().currentUser;
    final name = user?.fullName ?? 'Mawinga';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : '?';

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.4)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.surface,
                  child: Text(initials,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
              const SizedBox(height: 20),
              Divider(color: cs.onSurface.withValues(alpha: 0.06), height: 1),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Uicons.rightFromBracket, color: Color(0xFFE53935), size: 18),
                ),
                title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
                ),
                trailing: const Icon(Uicons.angleRight, size: 14, color: Color(0xFFE53935)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLogoutConfirmation(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            Text('Logout?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Are you sure you want to log out of your Mawinga account?',
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
            child: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    BrokerDashboardLoaded state,
    ColorScheme colorScheme,
  ) {
    final broker = state.broker;
    final analytics = state.analytics;
    final approved = broker.isApproved;

    final statusLabels = {
      'pending_kyc': 'Complete KYC',
      'kyc_submitted': 'KYC Submitted',
      'under_review': 'Under Review',
      'approved': 'Approved',
      'rejected': 'Action Required',
      'suspended': 'Suspended',
    };

    final quickActions = [
      {'title': 'KYC', 'desc': approved ? 'Verified' : 'Complete verification', 'icon': Uicons.shieldCheck, 'route': AppConstants.brokerKycRoute},
      {'title': 'Wallet', 'desc': approved ? 'Balance & payouts' : 'Locked', 'icon': Uicons.wallet, 'route': AppConstants.brokerWalletRoute},
      {'title': 'Find Products', 'desc': approved ? 'Browse & sell' : 'Locked', 'icon': Uicons.search, 'route': AppConstants.mawingaFindProductsRoute},
      {'title': 'Share & Earn', 'desc': approved ? 'Share products' : 'Locked', 'icon': Uicons.share, 'route': AppConstants.mawingaShareEarnRoute},
      {'title': 'My Products', 'desc': approved ? 'Your listings' : 'Locked', 'icon': Uicons.box, 'route': AppConstants.brokerProductsRoute},
      {'title': 'Opportunities', 'desc': approved ? 'Browse campaigns' : 'Locked', 'icon': Uicons.barChart, 'route': AppConstants.brokerOpportunitiesRoute},
      {'title': 'Earnings', 'desc': approved ? 'Commission history' : 'Locked', 'icon': Uicons.sackDollar, 'route': AppConstants.brokerEarningsRoute},
      {'title': 'Analytics', 'desc': approved ? 'Performance' : 'Locked', 'icon': Uicons.chartPie, 'route': AppConstants.brokerAnalyticsRoute},
      {'title': 'Leaderboard', 'desc': approved ? 'Top Mawinga' : 'Locked', 'icon': Uicons.trophy, 'route': AppConstants.mawingaLeaderboardRoute},
      {'title': 'Academy', 'desc': 'Learn & grow', 'icon': Uicons.book, 'route': AppConstants.mawingaAcademyRoute},
      {'title': 'My Store', 'desc': approved ? 'Digital store' : 'Locked', 'icon': Uicons.shop, 'route': AppConstants.mawingaStoreRoute},
      {'title': 'Invite', 'desc': 'Refer & earn', 'icon': Uicons.user, 'route': AppConstants.mawingaReferralRoute},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XERIN MAWINGA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome, ${broker.firstName ?? 'Mawinga'}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mawinga ID: ${broker.brokerCode}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabels[broker.status] ?? broker.status,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (approved && analytics != null) ...[
            const SizedBox(height: 16),
            _buildLevelCard(context, analytics, colorScheme),
          ],
          if (!approved) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Uicons.shieldCheck, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Complete identity verification to activate your Broker account.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Products, promotion opportunities, earnings and wallet access stay locked until an administrator approves your KYC.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  if (broker.statusReason != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        broker.statusReason!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => context.push(AppConstants.brokerKycRoute),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Open KYC Verification'),
                  ),
                ],
              ),
            ),
          ],
          if (approved && analytics != null) ...[
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _metricCard(context, 'Referral Clicks',
                    analytics.totalClicks.toString(),
                    '${analytics.uniqueVisitors} unique', colorScheme),
                _metricCard(context, 'Attributed Orders',
                    analytics.attributedOrders.toString(),
                    '${analytics.conversionRate}% conversion', colorScheme),
                _metricCard(context, 'Available Earnings',
                    analytics.availableEarnings,
                    '${analytics.pendingEarnings} pending', colorScheme),
                _metricCard(context, 'Wallet',
                    analytics.walletAvailable,
                    '${analytics.walletPaidOut} paid out', colorScheme),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: quickActions.map((action) {
              final isLocked = !approved && action['title'] != 'KYC';
              return GestureDetector(
                onTap: isLocked
                    ? null
                    : () => context.push(action['route'] as String),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? colorScheme.onSurface.withValues(alpha: 0.03)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLocked
                          ? colorScheme.onSurface.withValues(alpha: 0.08)
                          : colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            size: 22,
                            color: isLocked
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : colorScheme.primary,
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 6),
                            Icon(Uicons.lock, size: 14,
                                color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Text(
                        action['title'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isLocked
                              ? colorScheme.onSurface.withValues(alpha: 0.4)
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, BrokerAnalyticsOverviewModel analytics, ColorScheme cs) {
    final totalSales = analytics.successfulSales;
    final currentLevel = MawingaLevel.getLevelForSales(totalSales);
    final nextLevel = MawingaLevel.getNextLevel(currentLevel);
    final isMaxLevel = currentLevel.name == nextLevel.name;
    final salesInLevel = totalSales - currentLevel.minSales;
    final salesNeeded = isMaxLevel ? 0 : nextLevel.minSales - totalSales;
    final levelRange = currentLevel.maxSales - currentLevel.minSales + 1;
    final progress = isMaxLevel ? 1.0 : (salesInLevel / levelRange).clamp(0.0, 1.0);

    final levelColors = {
      'Starter': Colors.grey,
      'Bronze': const Color(0xFFB45309),
      'Silver': const Color(0xFF64748B),
      'Gold': const Color(0xFFD97706),
      'Platinum': const Color(0xFF7C3AED),
    };
    final levelColor = levelColors[currentLevel.name] ?? cs.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentLevel.name == 'Platinum' ? Uicons.star :
                  currentLevel.name == 'Gold' ? Uicons.crown :
                  currentLevel.name == 'Silver' ? Uicons.trophy :
                  currentLevel.name == 'Bronze' ? Uicons.medal :
                  Uicons.seedling,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentLevel.name} Mawinga',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalSales total sales',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: cs.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(levelColor),
            ),
          ),
          const SizedBox(height: 8),
          if (!isMaxLevel)
            Text(
              'You need $salesNeeded more sales to reach ${nextLevel.name}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            )
          else
            Text(
              'Maximum level reached! You are a top Mawinga.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: levelColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String title, String value,
      String subtitle, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
