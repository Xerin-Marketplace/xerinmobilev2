import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  String? _statusFilter;
  bool _isReloading = false;

  static const _statusOptions = [
    {'value': null, 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'failed', 'label': 'Failed'},
    {'value': 'refunded', 'label': 'Refunded'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadPayments();
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
        title: const Text('Payments'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(cs),
            Expanded(
              child: BlocConsumer<AdminCubit, AdminState>(
                listener: (context, state) {
                  if (state is AdminError) {
                    NotificationService().error(state.message);
                  }
                },
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AdminPaymentsLoaded) {
                    return _buildContent(state, cs);
                  }
                  if (!_isReloading) {
                    _isReloading = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<AdminCubit>().loadPayments(status: _statusFilter);
                      _isReloading = false;
                    });
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final value = opt['value'];
            final isSelected = _statusFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt['label']!),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _statusFilter = value);
                  context.read<AdminCubit>().loadPayments(status: value);
                },
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent(AdminPaymentsLoaded state, ColorScheme cs) {
    if (state.payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.creditCard,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Payments',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<AdminCubit>().loadPayments(status: _statusFilter),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final payment = state.payments[index];
          final status = payment['status']?.toString() ?? 'pending';
          final amount = payment['amount']?.toString() ?? '0';
          final currency = payment['currency']?.toString() ?? 'TZS';
          final method = payment['method']?.toString() ?? '';
          final orderId = payment['order_id']?.toString() ?? '';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text('Order #$orderId',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('$amount $currency',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                  if (method.isNotEmpty)
                    Text(method,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
              trailing: _statusBadge(status),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      case 'refunded':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
