import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

class BrokerAnalyticsPage extends StatefulWidget {
  const BrokerAnalyticsPage({super.key});

  @override
  State<BrokerAnalyticsPage> createState() => _BrokerAnalyticsPageState();
}

class _BrokerAnalyticsPageState extends State<BrokerAnalyticsPage> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadAnalytics(days: _selectedDays);
  }

  void _changePeriod(int days) {
    setState(() => _selectedDays = days);
    context.read<BrokerCubit>().loadAnalytics(days: days);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Uicons.calendar),
            onSelected: _changePeriod,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<BrokerCubit, BrokerState>(
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerAnalyticsLoaded) {
            return _buildAnalytics(context, state.overview, colorScheme);
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
                    onPressed: () =>
                        context.read<BrokerCubit>().loadAnalytics(days: _selectedDays),
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

  Widget _buildAnalytics(
    BuildContext context,
    BrokerAnalyticsOverviewModel data,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last $_selectedDays days',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _statCard(context, 'Total Clicks', data.totalClicks.toString(),
                  '${data.uniqueVisitors} unique visitors', colorScheme),
              _statCard(context, 'Attributed Orders',
                  data.attributedOrders.toString(),
                  '${data.attributedCustomers} customers', colorScheme),
              _statCard(context, 'Successful Sales',
                  data.successfulSales.toString(),
                  '${data.refundedSales} refunded', colorScheme),
              _statCard(context, 'Conversion Rate',
                  '${data.conversionRate}%', '', colorScheme),
              _statCard(context, 'Pending Earnings',
                  data.pendingEarnings, data.currency, colorScheme),
              _statCard(context, 'Available Earnings',
                  data.availableEarnings, data.currency, colorScheme),
              _statCard(context, 'Lifetime Earnings',
                  data.lifetimeEarnings, data.currency, colorScheme),
              _statCard(context, 'Wallet Available',
                  data.walletAvailable, data.currency, colorScheme),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _productStatCard(context, 'Active',
                    data.ownProductsActive.toString(), Colors.green, colorScheme),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _productStatCard(context, 'Draft',
                    data.ownProductsDraft.toString(), Colors.orange, colorScheme),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _productStatCard(context, 'Expired',
                    data.ownProductsExpired.toString(), Colors.red, colorScheme),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Promotions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _promoCard(context, 'Currently Promoting',
                    data.currentlyPromoting.toString(), colorScheme),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _promoCard(context, 'Available Opportunities',
                    data.availableOpportunities.toString(), colorScheme),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value,
      String subtitle, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productStatCard(BuildContext context, String label, String value,
      Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoCard(BuildContext context, String label, String value,
      ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
