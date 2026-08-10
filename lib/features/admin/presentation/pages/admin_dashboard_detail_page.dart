import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/admin_dashboard_cubit.dart';
import '../../data/models/admin_dashboard_model.dart';

class AdminDashboardDetailPage extends StatefulWidget {
  const AdminDashboardDetailPage({super.key});

  @override
  State<AdminDashboardDetailPage> createState() => _AdminDashboardDetailPageState();
}

class _AdminDashboardDetailPageState extends State<AdminDashboardDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdminDashboardCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Alerts'),
            Tab(text: 'Activity'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              context.read<AdminDashboardCubit>().loadDashboard(period: value);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'today', child: Text('Today')),
              PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              PopupMenuItem(value: '30d', child: Text('Last 30 days')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _AlertsTab(),
          _ActivityTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading) {
          return _buildLoadingSkeleton();
        }
        if (state is AdminDashboardError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          );
        }
        if (state is AdminDashboardSummaryLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AdminDashboardCubit>().loadDashboard(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle('Sales'),
                _KpiGrid([
                  _KpiItem('GMV', state.sales.gmv.toStringAsFixed(0), Icons.trending_up, Colors.green),
                  _KpiItem('Discounts', state.sales.discounts.toStringAsFixed(0), Icons.local_offer, Colors.orange),
                  _KpiItem('Shipping', state.sales.shipping.toStringAsFixed(0), Icons.local_shipping, Colors.blue),
                ], 2),
                const SizedBox(height: 16),
                _SectionTitle('Orders & Customers'),
                _KpiGrid([
                  _KpiItem('Total Orders', state.summary.totalOrders.toString(), Icons.shopping_bag, Colors.purple),
                  _KpiItem('Total Users', state.summary.totalUsers.toString(), Icons.people, Colors.indigo),
                  _KpiItem('Verified', state.customers.verified.toString(), Icons.verified_user, Colors.teal),
                ], 2),
                const SizedBox(height: 16),
                _SectionTitle('Sellers & Products'),
                _KpiGrid([
                  _KpiItem('Sellers', state.sellers.total.toString(), Icons.store, Colors.brown),
                  _KpiItem('Approved', state.sellers.approved.toString(), Icons.check_circle, Colors.green),
                  _KpiItem('Pending', state.sellers.pending.toString(), Icons.pending, Colors.amber),
                  _KpiItem('Products', state.products.total.toString(), Icons.inventory, Colors.cyan),
                  _KpiItem('Approved', state.products.approved.toString(), Icons.check_circle, Colors.green),
                  _KpiItem('Pending', state.products.pendingReview.toString(), Icons.pending, Colors.amber),
                ], 2),
                const SizedBox(height: 16),
                _SectionTitle('Payments & Refunds'),
                _KpiGrid([
                  _KpiItem('Payments', state.payments.total.toString(), Icons.payment, Colors.blue),
                  _KpiItem('Failed', state.payments.failed.toString(), Icons.error, Colors.red),
                  _KpiItem('Refunds', state.refunds.total.toString(), Icons.undo, Colors.orange),
                  _KpiItem('Refund Pending', state.refunds.pending.toString(), Icons.pending, Colors.amber),
                ], 2),
                const SizedBox(height: 16),
                _SectionTitle('Delivery & Notifications'),
                _KpiGrid([
                  _KpiItem('Deliveries', state.delivery.total.toString(), Icons.local_shipping, Colors.indigo),
                  _KpiItem('Failed', state.delivery.failed.toString(), Icons.error, Colors.red),
                  _KpiItem('Notifications', state.notifications.total.toString(), Icons.notifications, Colors.teal),
                  _KpiItem('Failed', state.notifications.failed.toString(), Icons.error_outline, Colors.red),
                ], 2),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: List.generate(6, (_) => Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminAlertsLoaded) {
          if (state.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No system alerts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('All clear!', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.alerts.length,
            itemBuilder: (context, index) {
              final alert = state.alerts[index];
              return _AlertCard(alert: alert);
            },
          );
        }
        if (state is AdminDashboardError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminActivityLogsLoaded) {
          if (state.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No activity logs',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Activity will appear here',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.logs.length,
            itemBuilder: (context, index) {
              final log = state.logs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.history, size: 24),
                  title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    if (log.resourceType != null) log.resourceType!,
                    if (log.details != null) log.details!,
                    if (log.createdAt != null) log.createdAt!.substring(0, 19),
                  ].join(' - ')),
                ),
              );
            },
          );
        }
        if (state is AdminDashboardError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminDashboardCubit>().loadDashboard(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiItem> items;
  final int crossAxisCount;

  const _KpiGrid(this.items, this.crossAxisCount);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.05),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 22),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: item.color),
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiItem(this.label, this.value, this.icon, this.color);
}

class _AlertCard extends StatelessWidget {
  final AdminSystemAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severityColor = {
      'critical': Colors.red,
      'high': Colors.deepOrange,
      'medium': Colors.amber,
      'low': Colors.blue,
    }[alert.severity] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: severityColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.message, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alert.type,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (!alert.resolved)
                  FilledButton.tonal(
                    onPressed: () => context.read<AdminDashboardCubit>().resolveAlert(alert.id),
                    child: const Text('Resolve'),
                  )
                else
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Resolved', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Failed to load',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
