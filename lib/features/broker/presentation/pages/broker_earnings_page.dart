import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Broker Finance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
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
          if (state is BrokerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadEarnings(),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BrokerEarningsLoaded state, ColorScheme cs) {
    final summary = state.summary;
    final commissions = state.commissions;

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadEarnings(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _infoBanner(cs),
          const SizedBox(height: 16),
          _summaryCard(cs, summary),
          const SizedBox(height: 20),
          _sectionTitle('Commission history', cs),
          const SizedBox(height: 4),
          Text('${summary.totalRecords} attributed commission record(s)',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 12),
          _commissionHistory(cs, commissions),
        ],
      ),
    );
  }

  Widget _infoBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mawingaPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mawingaPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Uicons.circleInfo, size: 18, color: _mawingaPrimary),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Commission is created only after a successful attributed payment. It stays pending while funds are held and becomes available only after Xerin\'s trusted escrow release milestone. Wallet withdrawal starts in B6.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
        )),
      ]),
    );
  }

  Widget _summaryCard(ColorScheme cs, dynamic summary) {
    final items = [
      ('Pending commission', summary.pendingAmount, const Color(0xFFF59E0B), Uicons.clock),
      ('Available commission', summary.availableAmount, const Color(0xFF22C55E), Uicons.wallet),
      ('Reversed / refunded', summary.reversedAmount, const Color(0xFFEF4444), Uicons.arrowTrendDown),
      ('Lifetime attributed', summary.lifetimeCommission, _mawingaPrimary, Uicons.trophy),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: items.map((item) => _summaryRow(cs, item.$1, item.$2, item.$3, item.$4)).toList()),
    );
  }

  Widget _summaryRow(ColorScheme cs, String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface))),
        Text('TSh $value',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface)),
      ]),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _commissionHistory(ColorScheme cs, List<Map<String, dynamic>> commissions) {
    if (commissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(children: [
          Icon(Uicons.coin, size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('No commission records yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text('Successful purchases through your B4 referral links will appear here.',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
        ]),
      );
    }

    return Column(children: commissions.map((c) => _commissionCard(cs, c)).toList());
  }

  Widget _commissionCard(ColorScheme cs, Map<String, dynamic> commission) {
    final amount = commission['amount']?.toString() ?? '0';
    final status = commission['status']?.toString() ?? 'pending';
    final productName = commission['product_name']?.toString() ?? commission['order_id']?.toString() ?? 'Commission';
    final createdAt = commission['created_at']?.toString() ?? '';

    final statusMap = {
      'pending': const Color(0xFFF59E0B),
      'available': const Color(0xFF22C55E),
      'paid': const Color(0xFF22C55E),
      'reversed': const Color(0xFFEF4444),
      'refunded': const Color(0xFFEF4444),
    };
    final statusColor = statusMap[status] ?? const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Uicons.coin, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(productName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('TSh $amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _mawingaPrimary)),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_formatDate(createdAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
