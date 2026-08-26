import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerAnalyticsPage extends StatefulWidget {
  const SellerAnalyticsPage({super.key});

  @override
  State<SellerAnalyticsPage> createState() => _SellerAnalyticsPageState();
}

class _SellerAnalyticsPageState extends State<SellerAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerAnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadAnalytics(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(context, state.overview),
                  const SizedBox(height: 16),
                  if (state.sales.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Sales Trend'),
                    const SizedBox(height: 8),
                    _buildSalesChart(context, state.sales),
                    const SizedBox(height: 24),
                  ],
                  if (state.products.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Top Products'),
                    const SizedBox(height: 8),
                    ...state.products.map((p) => _buildProductRankTile(context, p)),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          if (state is SellerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerCubit>().loadAnalytics(),
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

  Widget _buildOverviewCards(BuildContext context, SellerAnalyticsOverviewModel overview) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(context, 'Gross Sales', _formatMoney(overview.grossSales, overview.currency), Uicons.coin, Colors.blue),
        _buildMetricCard(context, 'Net Earnings', _formatMoney(overview.sellerNetEarnings, overview.currency), Uicons.wallet, Colors.green),
        _buildMetricCard(context, 'Orders', '${overview.orders}', Uicons.box, Colors.orange),
        _buildMetricCard(context, 'Units Sold', '${overview.unitsSold}', Uicons.tags, Colors.purple),
        _buildMetricCard(context, 'Avg Order Value', _formatMoney(overview.averageOrderValue, overview.currency), Uicons.chartSimple, Colors.teal),
        _buildMetricCard(context, 'Refund Rate', '${overview.refundRatePercent.toStringAsFixed(1)}%', Uicons.arrowTrendDown, Colors.red),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, List<AnalyticsSeriesPointModel> sales) {
    final maxVal = sales.fold<double>(0.0, (max, p) => p.value > max ? p.value : max);
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(sales, maxVal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRankTile(BuildContext context, AnalyticsRankingRowModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('${product.units}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${product.orderCount} orders | ${_formatMoney(product.grossSales)} gross'),
        trailing: Text(_formatMoney(product.netEarnings), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }

  String _formatMoney(double amount, [String currency = 'TZS']) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }
}

class _BarChartPainter extends CustomPainter {
  final List<AnalyticsSeriesPointModel> data;
  final double maxVal;

  _BarChartPainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / data.length * 0.7;
    final gap = size.width / data.length * 0.3;
    final paint = Paint()..color = Colors.blue..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final barHeight = (data[i].value / maxVal) * size.height * 0.9;
      final x = i * (barWidth + gap) + gap / 2;
      final y = size.height - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, barHeight), const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
