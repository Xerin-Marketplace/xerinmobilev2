import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminFinancePage extends StatefulWidget {
  const AdminFinancePage({super.key});

  @override
  State<AdminFinancePage> createState() => _AdminFinancePageState();
}

class _AdminFinancePageState extends State<AdminFinancePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<AdminCubit>().loadFinanceData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        title: const Text('Finance'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Escrow'),
            Tab(text: 'Reconciliation'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is AdminError) {
              NotificationService().error(state.message);
            }
            if (state is AdminActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminFinanceLoaded) {
              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _EscrowTab(data: state.escrowHolds),
                  _ReconciliationTab(data: state.reconciliation),
                  _SettingsTab(settings: state.settings),
                ],
              );
            }
            if (!_isReloading) {
              _isReloading = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AdminCubit>().loadFinanceData();
                _isReloading = false;
              });
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _EscrowTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _EscrowTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = data['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      return Center(
        child: Text('No escrow holds',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hold = results[index] as Map<String, dynamic>;
        return _EscrowHoldCard(hold: hold);
      },
    );
  }
}

class _EscrowHoldCard extends StatelessWidget {
  final Map<String, dynamic> hold;

  const _EscrowHoldCard({required this.hold});

  Color _statusColor(String? status) {
    switch (status) {
      case 'held':
        return Colors.orange;
      case 'released':
        return Colors.green;
      case 'disputed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = hold['status']?.toString();
    final amount = hold['amount']?.toString() ?? '0';
    final currency = hold['currency']?.toString() ?? 'TZS';
    final orderId = hold['order_id']?.toString() ?? '';

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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (status ?? 'unknown').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$amount $currency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order: $orderId',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            if (status == 'held') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showReleaseDialog(context, hold['id']),
                    icon: const Icon(Uicons.check, size: 16),
                    label: const Text('Release'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDisputeDialog(context, hold['id']),
                    icon: const Icon(Uicons.circleExclamation, size: 16),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    label: const Text('Dispute'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReleaseDialog(BuildContext context, dynamic holdId) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Escrow'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AdminCubit>()
                  .releaseEscrowHold(holdId.toString(), note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, dynamic holdId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispute Escrow'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context
                  .read<AdminCubit>()
                  .disputeEscrowHold(holdId.toString(), reasonCtrl.text.trim());
            },
            child: const Text('Dispute'),
          ),
        ],
      ),
    );
  }
}

class _ReconciliationTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReconciliationTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = data['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      return Center(
        child: Text('No reconciliation records',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = results[index] as Map<String, dynamic>;
        final status = record['status']?.toString() ?? '';
        final orderId = record['order_id']?.toString() ?? '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text('Order: $orderId',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(status.toUpperCase(),
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            trailing: status == 'pending'
                ? FilledButton.tonal(
                    onPressed: () => context
                        .read<AdminCubit>()
                        .reconcileOrder(orderId),
                    child: const Text('Reconcile'),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final Map<String, dynamic>? settings;

  const _SettingsTab({this.settings});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late final TextEditingController _escrowPeriodCtrl;
  late final TextEditingController _commissionCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.settings ?? {};
    _escrowPeriodCtrl = TextEditingController(
        text: s['escrow_release_period_hours']?.toString() ?? '72');
    _commissionCtrl = TextEditingController(
        text: s['default_commission_rate']?.toString() ?? '5.0');
  }

  @override
  void dispose() {
    _escrowPeriodCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Finance Settings',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 24),
          _buildField(cs, 'Escrow Release Period (hours)', _escrowPeriodCtrl),
          const SizedBox(height: 16),
          _buildField(cs, 'Default Commission Rate (%)', _commissionCtrl),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                context.read<AdminCubit>().updateFinanceSettings({
                  'escrow_release_period_hours':
                      int.tryParse(_escrowPeriodCtrl.text) ?? 72,
                  'default_commission_rate':
                      double.tryParse(_commissionCtrl.text) ?? 5.0,
                });
              },
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(ColorScheme cs, String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
          ),
        ),
      ],
    );
  }
}
