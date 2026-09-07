import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../data/models/seller_models.dart';
import '../../cubit/seller_cubit.dart';

class SellerHomeTab extends StatelessWidget {
  final SellerDashboardLoaded state;
  final VoidCallback onRefresh;

  const SellerHomeTab({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: _buildDashboard(context, state),
    );
  }

  Widget _buildDashboard(BuildContext context, SellerDashboardLoaded state) {
    final d = state.dashboard;
    final seller = state.seller;
    final orderSummary = state.orderSummary;
    final inventorySummary = state.inventorySummary;
    final wallet = state.wallet;
    final isPending = seller?.status == 'pending' || seller?.status == 'under_review';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (isPending) _buildPendingBanner(context, seller!.status),
        _buildStoreReadiness(context, seller, d),
        const SizedBox(height: 20),
        _buildSectionTitle(context, 'Overview'),
        const SizedBox(height: 10),
        _buildMetricsGrid(context, d),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Orders'),
        const SizedBox(height: 10),
        _buildOrdersCard(context, d, orderSummary),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Catalog & Inventory'),
        const SizedBox(height: 10),
        _buildCatalogInventoryCard(context, d, inventorySummary),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Finance'),
        const SizedBox(height: 10),
        _buildFinanceCard(context, d, wallet),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Reputation'),
        const SizedBox(height: 10),
        _buildReputationCard(context, d),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'Quick Actions'),
        const SizedBox(height: 10),
        _buildQuickActions(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPendingBanner(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Uicons.clock, size: 20, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status == 'pending'
                  ? 'Your seller account is pending approval. Upload KYC documents to speed up the process.'
                  : 'Your seller account is under review. We\'ll notify you once approved.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreReadiness(BuildContext context, SellerModel? seller, SellerDashboardPerformanceModel d) {
    final cs = Theme.of(context).colorScheme;
    final checks = [
      ('Business profile', seller?.businessName != null),
      ('KYC documents', seller?.isVerified == true),
      ('Payout account', d.walletAvailable > 0 || d.walletPending > 0),
      ('Catalog started', d.productsTotal > 0),
    ];
    final completed = checks.where((c) => c.$2).length;
    final percent = (completed / checks.length * 100).round();
    final isComplete = percent == 100;
    final progressColor = isComplete ? const Color(0xFF22C55E) : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72, height: 72,
            child: CustomPaint(
              painter: _CircleProgressPainter(
                progress: percent / 100,
                color: progressColor,
                trackColor: cs.onSurface.withValues(alpha: 0.06),
              ),
              child: Center(
                child: Text('$percent%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: progressColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store readiness', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(isComplete ? 'All set!' : '$completed of ${checks.length} completed',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: checks.map((c) => _buildCheckChip(cs, c.$1, c.$2)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckChip(ColorScheme cs, String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF22C55E).withValues(alpha: 0.08) : cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check : Icons.circle_outlined, size: 12, color: done ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: done ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _buildMetricsGrid(BuildContext context, SellerDashboardPerformanceModel d) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildMetricTile(context, 'Products', '${d.productsTotal}', '${d.productsApproved} approved'),
        _buildMetricTile(context, 'Pending review', '${d.productsPendingReview}', 'Awaiting approval'),
        _buildMetricTile(context, 'Orders', '${d.ordersTotal}', '${d.ordersNew} new'),
        _buildMetricTile(context, 'Balance', _formatMoney(d.walletAvailable, d.walletCurrency), '${d.pendingPayouts} pending'),
        _buildMetricTile(context, 'Avg rating', d.ratingAverage.toStringAsFixed(1), '${d.reviewCount} reviews'),
        _buildMetricTile(context, 'Unanswered Q&A', '${d.unansweredQuestions}', 'Customer questions'),
      ],
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, String helper) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(helper, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.35)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildOrdersCard(BuildContext context, SellerDashboardPerformanceModel d, SellerOrderSummaryModel? summary) {
    final cs = Theme.of(context).colorScheme;
    final newOrders = summary?.newOrders ?? d.ordersNew;
    final processing = summary?.processingOrders ?? d.ordersProcessing;
    final ready = summary?.readyToShipOrders ?? d.ordersReadyToShip;
    final total = summary?.totalOrders ?? d.ordersTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildOrderStage(cs, 'New', newOrders),
              _buildDivider(cs),
              _buildOrderStage(cs, 'Processing', processing),
              _buildDivider(cs),
              _buildOrderStage(cs, 'Ready', ready),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(AppConstants.sellerOrdersRoute),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                Row(
                  children: [
                    Text('$total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.primary)),
                    const SizedBox(width: 4),
                    Icon(Uicons.angleRight, size: 14, color: cs.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStage(ColorScheme cs, String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: count > 0 ? cs.onSurface : cs.onSurface.withValues(alpha: 0.2))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Container(width: 1, height: 30, color: cs.onSurface.withValues(alpha: 0.06));
  }

  Widget _buildCatalogInventoryCard(BuildContext context, SellerDashboardPerformanceModel d, SellerInventorySummaryModel? summary) {
    final cs = Theme.of(context).colorScheme;
    final approved = d.productsApproved;
    final pending = d.productsPendingReview;
    final draft = d.productsTotal - approved - pending;
    final total = d.productsTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBarRow(cs, 'Approved', approved, total, const Color(0xFF22C55E)),
          const SizedBox(height: 10),
          _buildBarRow(cs, 'Pending', pending, total, const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          _buildBarRow(cs, 'Draft', draft, total, cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
          if (summary != null) ...[
            Row(
              children: [
                _buildInvStat(cs, 'Healthy', summary.totalVariants - summary.lowStockVariants - summary.outOfStockVariants, const Color(0xFF22C55E)),
                _buildInvStat(cs, 'Low', summary.lowStockVariants, const Color(0xFFF59E0B)),
                _buildInvStat(cs, 'Out', summary.outOfStockVariants, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(cs, 'Total units', '${summary.totalStockUnits}'),
            _buildInfoRow(cs, 'Inventory value', _formatMoney(summary.inventoryValue, 'TZS')),
          ] else
            Text('No inventory records yet', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildBarRow(ColorScheme cs, String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 32, child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildInvStat(ColorScheme cs, String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: count > 0 ? color : cs.onSurface.withValues(alpha: 0.2))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(BuildContext context, SellerDashboardPerformanceModel d, SellerWalletModel? wallet) {
    final cs = Theme.of(context).colorScheme;
    final available = wallet?.availableBalance ?? d.walletAvailable;
    final pending = wallet?.pendingBalance ?? d.walletPending;
    final reserved = wallet?.reservedBalance ?? d.walletReserved;
    final currency = wallet?.currency ?? d.walletCurrency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total wallet', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text(_formatMoney(available + pending + reserved, currency),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 16),
          _buildInfoRow(cs, 'Available', _formatMoney(available, currency)),
          _buildInfoRow(cs, 'Pending', _formatMoney(pending, currency)),
          _buildInfoRow(cs, 'Reserved', _formatMoney(reserved, currency)),
          if (wallet?.isFrozen == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Uicons.lock, size: 14, color: const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Text('Wallet is frozen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(AppConstants.sellerWalletRoute),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wallet & earnings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                Row(
                  children: [
                    Text('${d.pendingPayouts} pending payouts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                    const SizedBox(width: 4),
                    Icon(Uicons.angleRight, size: 14, color: cs.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationCard(BuildContext context, SellerDashboardPerformanceModel d) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppConstants.sellerReviewsRoute),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Uicons.star, size: 14, color: const Color(0xFFEAB308)),
                      const SizedBox(width: 4),
                      Text(d.ratingAverage.toStringAsFixed(1), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                      Text(' / 5', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${d.reviewCount} reviews', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 36, color: cs.onSurface.withValues(alpha: 0.06)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => context.push(AppConstants.sellerQuestionsRoute),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.unansweredQuestions}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: d.unansweredQuestions > 0 ? const Color(0xFFEF4444) : cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('Unanswered Q&A', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: cs.onSurface.withValues(alpha: 0.06)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => context.push(AppConstants.sellerPromotionsRoute),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.activePromotions}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('Promotions', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actions = [
      ('Add product', Uicons.plus, AppConstants.sellerProductsRoute),
      ('Inventory', Uicons.warehouse, AppConstants.sellerInventoryRoute),
      ('Store', Uicons.shop, AppConstants.sellerStoreRoute),
      ('Wallet', Uicons.wallet, AppConstants.sellerWalletRoute),
      ('Analytics', Uicons.chartSimple, AppConstants.sellerAnalyticsRoute),
      ('KYC', Uicons.shieldCheck, AppConstants.sellerKycRoute),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final (label, icon, route) = actions[index];
        return GestureDetector(
          onTap: () => context.push(route),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatMoney(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CircleProgressPainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    canvas.drawCircle(
      center, radius,
      Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = 6,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
