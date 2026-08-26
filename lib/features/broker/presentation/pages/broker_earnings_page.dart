import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/broker_models.dart';
import '../cubit/broker_cubit.dart';

class BrokerEarningsPage extends StatefulWidget {
  const BrokerEarningsPage({super.key});

  @override
  State<BrokerEarningsPage> createState() => _BrokerEarningsPageState();
}

class _BrokerEarningsPageState extends State<BrokerEarningsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        child: BlocConsumer<BrokerCubit, BrokerState>(
          listener: (context, state) {
            if (state is BrokerError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is BrokerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BrokerEarningsLoaded) {
              return _buildContent(state, cs);
            }
            return Center(
              child: Text('Loading...',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BrokerEarningsLoaded state, ColorScheme cs) {
    final summary = state.summary;

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadEarnings(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earnings',
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.lifetimeEarnings} TZS',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
              Expanded(
                child: _statCard(cs, 'Pending',
                    '${summary.pendingEarnings} TZS', Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(cs, 'Paid Out',
                    '${summary.walletPaidOut} TZS', Colors.green),
              ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Commission History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            if (state.commissions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No commissions yet',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ),
              )
            else
              ...state.commissions.map((c) => _commissionCard(c, cs)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(ColorScheme cs, String label, String value, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _commissionCard(Map<String, dynamic> commission, ColorScheme cs) {
    final amount = commission['amount']?.toString() ?? '0';
    final status = commission['status']?.toString() ?? 'pending';
    final productName =
        commission['product_name']?.toString() ?? 'Unknown Product';
    final createdAt = commission['created_at']?.toString() ?? '';

    Color statusColor;
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(productName,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$amount TZS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary)),
            if (createdAt.isNotEmpty)
              Text(createdAt,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
          ),
        ),
      ),
    );
  }
}
