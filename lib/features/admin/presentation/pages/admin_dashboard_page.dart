import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () =>
                context.read<AdminCubit>().loadDashboard(refresh: true),
          ),
        ],
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<AdminCubit>().loadDashboard(refresh: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryGrid(context, state),
                  const SizedBox(height: 16),
                  _buildOrdersBreakdown(context, state),
                  const SizedBox(height: 16),
                  _buildAlertsSection(context, state),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                ],
              ),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCubit>().loadDashboard(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, AdminDashboardLoaded state) {
    final s = state.summary;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _metricCard('Total Orders', s.totalOrders.toString(), Uicons.shoppingBag, Colors.blue),
        _metricCard('GMV', '${s.currency} ${_fmt(s.gmv)}', Uicons.dollar, Colors.green),
        _metricCard('Total Users', s.totalUsers.toString(), Uicons.users, Colors.purple),
        _metricCard('Sellers', s.totalSellers.toString(), Uicons.storeAlt, Colors.orange),
        _metricCard('Products', s.totalProducts.toString(), Uicons.boxOpen, Colors.teal),
        _metricCard('Discounts', '${s.currency} ${_fmt(s.totalDiscounts)}', Uicons.tags, Colors.red),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersBreakdown(BuildContext context, AdminDashboardLoaded state) {
    final orders = state.orders;
    if (orders == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orders by Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...orders.byStatus.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_humanize(e.key)),
                      Text('${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, AdminDashboardLoaded state) {
    if (state.alerts.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('System Alerts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () =>
                      context.read<AdminCubit>().loadAlerts(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...state.alerts.take(5).map((alert) => _alertTile(context, alert)),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(BuildContext context, AdminSystemAlertModel alert) {
    final color = alert.severity == 'critical'
        ? Colors.red
        : alert.severity == 'warning'
            ? Colors.orange
            : Colors.blue;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Uicons.bell, size: 20, color: color),
      title: Text(alert.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(alert.alertType, style: const TextStyle(fontSize: 12)),
      trailing: alert.isResolved
          ? const Icon(Uicons.checkCircle, size: 18, color: Colors.green)
          : TextButton(
              onPressed: () => context.read<AdminCubit>().resolveAlert(alert.id),
              child: const Text('Resolve'),
            ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _actionTile('Sellers', Uicons.storeAlt, Colors.orange, () =>
                    context.push(AppConstants.adminSellersRoute)),
                _actionTile('Products', Uicons.boxOpen, Colors.teal, () =>
                    context.push(AppConstants.adminProductsRoute)),
                _actionTile('Orders', Uicons.shoppingBag, Colors.blue, () =>
                    context.push(AppConstants.adminOrdersRoute)),
                _actionTile('Users', Uicons.users, Colors.purple, () =>
                    context.push(AppConstants.adminUsersRoute)),
                _actionTile('Wallets', Uicons.wallet, Colors.green, () =>
                    context.push(AppConstants.adminWalletsRoute)),
                _actionTile('Refunds', Uicons.rotateLeft, Colors.red, () =>
                    context.push(AppConstants.adminRefundsRoute)),
                _actionTile('Reviews', Uicons.star, Colors.amber, () =>
                    context.push(AppConstants.adminReviewsRoute)),
                _actionTile('Analytics', Uicons.barChart, Colors.indigo, () =>
                    context.push(AppConstants.adminAnalyticsRoute)),
                _actionTile('Alerts', Uicons.bell, Colors.pink, () =>
                    context.push(AppConstants.adminAlertsRoute)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
