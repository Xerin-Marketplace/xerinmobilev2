import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadAnalytics(),
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
          if (state is AdminAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<AdminCubit>().loadAnalytics(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(context, state.overview),
                  const SizedBox(height: 16),
                  if (state.sales.isNotEmpty) ...[
                    _buildSalesChart(context, state.sales),
                    const SizedBox(height: 16),
                  ],
                  if (state.sellers.isNotEmpty) ...[
                    _buildSellerRanking(context, state.sellers),
                    const SizedBox(height: 16),
                  ],
                  if (state.products.isNotEmpty)
                    _buildProductRanking(context, state.products),
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
                    onPressed: () => context.read<AdminCubit>().loadAnalytics(),
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

  Widget _buildOverviewCards(BuildContext context, AdminAnalyticsOverviewModel o) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _metricCard('Revenue', '${o.currency} ${_fmt(o.totalRevenue)}', Uicons.dollar, Colors.green),
        _metricCard('Orders', o.totalOrders.toString(), Uicons.shoppingBag, Colors.blue),
        _metricCard('Avg Order', '${o.currency} ${_fmt(o.avgOrderValue)}', Uicons.chartSimple, Colors.purple),
        _metricCard('Customers', o.totalCustomers.toString(), Uicons.users, Colors.orange),
        _metricCard('Sellers', o.totalSellers.toString(), Uicons.storeAlt, Colors.teal),
        _metricCard('Products', o.totalProducts.toString(), Uicons.boxOpen, Colors.indigo),
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
                  child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, List<AdminAnalyticsSalesPointModel> sales) {
    final maxRevenue = sales.fold<double>(0, (a, b) => max(a, b.revenue));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: _SalesChartPainter(sales, maxRevenue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerRanking(BuildContext context, List<AdminAnalyticsSellerRankingModel> sellers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Sellers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sellers.take(10).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: i < 3
                      ? [Colors.amber, Colors.grey, Colors.brown][i]
                      : Colors.grey.shade300,
                  child: Text('${i + 1}', style: TextStyle(color: i < 3 ? Colors.white : Colors.black54)),
                ),
                title: Text(s.sellerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.orders} orders | ${s.products} products'),
                trailing: Text('${_fmt(s.revenue)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRanking(BuildContext context, List<AdminAnalyticsProductRankingModel> products) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...products.take(10).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.blue)),
                ),
                title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${p.unitsSold} units sold'),
                trailing: Text('${_fmt(p.revenue)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _SalesChartPainter extends CustomPainter {
  final List<AdminAnalyticsSalesPointModel> sales;
  final double maxRevenue;

  _SalesChartPainter(this.sales, this.maxRevenue);

  @override
  void paint(Canvas canvas, Size size) {
    if (sales.isEmpty || maxRevenue == 0) return;

    final barWidth = size.width / sales.length;
    final paint = Paint()..color = Colors.blue.withValues(alpha: 0.7);

    for (var i = 0; i < sales.length; i++) {
      final barHeight = (sales[i].revenue / maxRevenue) * size.height * 0.85;
      final x = i * barWidth + barWidth * 0.15;
      final w = barWidth * 0.7;
      final y = size.height - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
