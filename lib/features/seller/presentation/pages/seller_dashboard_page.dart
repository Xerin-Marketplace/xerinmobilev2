import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Panel'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<SellerCubit>().loadDashboard(refresh: true),
          ),
        ],
      ),
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
          if (state is SellerDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadDashboard(refresh: true),
              child: _buildDashboard(context, state),
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
                    onPressed: () => context.read<SellerCubit>().loadDashboard(),
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

  Widget _buildDashboard(BuildContext context, SellerDashboardLoaded state) {
    final d = state.dashboard;
    final seller = state.seller;
    final orderSummary = state.orderSummary;
    final inventorySummary = state.inventorySummary;
    final wallet = state.wallet;

    final isPending = seller?.status == 'pending' || seller?.status == 'under_review';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        if (isPending) _buildPendingBanner(context, seller!.status),
        // Hero
        _buildHero(context, seller?.businessName ?? 'Your Store', seller?.status ?? 'unknown'),
        const SizedBox(height: 16),
        // Metric cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildMetricCard(
              context,
              label: 'Total Products',
              value: '${d.productsTotal}',
              helper: '${d.productsApproved} approved',
              icon: Uicons.shoppingBag,
              color: Colors.orange,
            ),
            _buildMetricCard(
              context,
              label: 'Pending Review',
              value: '${d.productsPendingReview}',
              helper: 'Awaiting approval',
              icon: Uicons.clock,
              color: Colors.amber,
            ),
            _buildMetricCard(
              context,
              label: 'Total Orders',
              value: '${d.ordersTotal}',
              helper: '${d.ordersNew} new',
              icon: Uicons.box,
              color: Colors.blue,
            ),
            _buildMetricCard(
              context,
              label: 'Available Balance',
              value: _formatMoney(d.walletAvailable, d.walletCurrency),
              helper: '${d.pendingPayouts} pending payout${d.pendingPayouts == 1 ? '' : 's'}',
              icon: Uicons.wallet,
              color: Colors.green,
            ),
            _buildMetricCard(
              context,
              label: 'Avg Rating',
              value: '${d.ratingAverage.toStringAsFixed(2)} / 5',
              helper: '${d.reviewCount} review${d.reviewCount == 1 ? '' : 's'}',
              icon: Uicons.star,
              color: Colors.amber,
            ),
            _buildMetricCard(
              context,
              label: 'Unanswered Q&A',
              value: '${d.unansweredQuestions}',
              helper: 'Customer questions',
              icon: Uicons.circleQuestion,
              color: d.unansweredQuestions > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Order pipeline
        if (orderSummary != null) ...[
          _buildSectionTitle(context, 'Order Pipeline'),
          const SizedBox(height: 8),
          _buildOrderPipeline(context, orderSummary),
          const SizedBox(height: 24),
        ],
        // Inventory summary
        if (inventorySummary != null) ...[
          _buildSectionTitle(context, 'Inventory Health'),
          const SizedBox(height: 8),
          _buildInventorySummary(context, inventorySummary),
          const SizedBox(height: 24),
        ],
        // Wallet summary
        if (wallet != null) ...[
          _buildSectionTitle(context, 'Wallet'),
          const SizedBox(height: 8),
          _buildWalletSummary(context, wallet),
          const SizedBox(height: 24),
        ],
        // Quick actions
        _buildSectionTitle(context, 'Quick Actions'),
        const SizedBox(height: 8),
        _buildQuickActions(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPendingBanner(BuildContext context, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Uicons.clock, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status == 'pending'
                  ? 'Your seller account is pending approval. Upload KYC documents to speed up the process.'
                  : 'Your seller account is under review. We\'ll notify you once approved.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, String businessName, String status) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required String helper,
    required IconData icon,
    required Color color,
  }) {
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOrderPipeline(BuildContext context, SellerOrderSummaryModel summary) {
    final stages = [
      ('New', summary.newOrders, Colors.blue),
      ('Accepted', summary.acceptedOrders, Colors.indigo),
      ('Processing', summary.processingOrders, Colors.orange),
      ('Ready to Ship', summary.readyToShipOrders, Colors.amber),
      ('Shipped', summary.shippedOrders, Colors.teal),
      ('Delivered', summary.deliveredOrders, Colors.green),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: stages.map((s) {
          final (label, count, color) = s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                Text(
                  '$count',
                  style: TextStyle(fontWeight: FontWeight.bold, color: count > 0 ? color : null),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventorySummary(BuildContext context, SellerInventorySummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total Products', '${summary.totalProducts}'),
          _buildSummaryRow('Total Stock Units', '${summary.totalStockUnits}'),
          _buildSummaryRow('Available Units', '${summary.availableUnits}'),
          _buildSummaryRow('Reserved Units', '${summary.reservedUnits}'),
          _buildSummaryRow('Low Stock Variants', '${summary.lowStockVariants}', highlight: summary.lowStockVariants > 0),
          _buildSummaryRow('Out of Stock', '${summary.outOfStockVariants}', highlight: summary.outOfStockVariants > 0),
          _buildSummaryRow('Inventory Value', _formatMoney(summary.inventoryValue, 'TZS')),
        ],
      ),
    );
  }

  Widget _buildWalletSummary(BuildContext context, SellerWalletModel wallet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Available', _formatMoney(wallet.availableBalance, wallet.currency)),
          _buildSummaryRow('Pending', _formatMoney(wallet.pendingBalance, wallet.currency)),
          _buildSummaryRow('Reserved', _formatMoney(wallet.reservedBalance, wallet.currency)),
          _buildSummaryRow('Paid Out', _formatMoney(wallet.paidOutBalance, wallet.currency)),
          if (wallet.isFrozen)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Uicons.lock, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('Wallet is frozen', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: highlight ? Colors.red : null)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: highlight ? Colors.red : null),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Orders', Uicons.box, AppConstants.sellerOrdersRoute),
      ('Products', Uicons.tags, AppConstants.sellerProductsRoute),
      ('Inventory', Uicons.warehouse, AppConstants.sellerInventoryRoute),
      ('Store', Uicons.shop, AppConstants.sellerStoreRoute),
      ('Wallet', Uicons.wallet, AppConstants.sellerWalletRoute),
      ('KYC', Uicons.shieldCheck, AppConstants.sellerKycRoute),
      ('Analytics', Uicons.chartSimple, AppConstants.sellerAnalyticsRoute),
      ('Promotions', Uicons.ticket, AppConstants.sellerPromotionsRoute),
      ('Reviews', Uicons.star, AppConstants.sellerReviewsRoute),
      ('Q&A', Uicons.circleQuestion, AppConstants.sellerQuestionsRoute),
      ('Cancellations', Uicons.circleXmark, AppConstants.sellerCancellationsRoute),
      ('Returns', Uicons.arrowLeft, AppConstants.sellerReturnsRoute),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final (label, icon, route) = actions[index];
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () => context.push(route),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: theme.colorScheme.primary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
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

  String _formatMoney(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }
}
