import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

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
        title: const Text('Broker Panel'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () =>
                context.read<BrokerCubit>().loadDashboard(refresh: true),
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
      {'title': 'Opportunities', 'desc': approved ? 'Browse campaigns' : 'Locked', 'icon': Uicons.barChart, 'route': AppConstants.brokerOpportunitiesRoute},
      {'title': 'Products', 'desc': approved ? 'Your listings' : 'Locked', 'icon': Uicons.box, 'route': AppConstants.brokerProductsRoute},
      {'title': 'Analytics', 'desc': approved ? 'Performance' : 'Locked', 'icon': Uicons.chartPie, 'route': AppConstants.brokerAnalyticsRoute},
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
                  'Broker Center',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome, ${broker.firstName ?? 'Broker'}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Broker ID: ${broker.brokerCode}',
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
