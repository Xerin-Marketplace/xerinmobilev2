import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../data/models/order_model.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'received_at_hub':
      case 'paid':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'User';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            if (state is CustomerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = state is CustomerLoaded ? state.orders : <OrderModel>[];
            final addresses = state is CustomerLoaded ? state.addresses : [];
            final notifications = state is CustomerLoaded ? state.notifications : [];
            final paymentMethods = state is CustomerLoaded ? state.paymentMethods : [];

            // Calculate stats
            final pendingCount = orders.where((o) => o.status.toLowerCase() == 'pending').length;
            final processingCount = orders.where((o) =>
                o.status.toLowerCase() == 'processing' || o.status.toLowerCase() == 'received_at_hub').length;
            final shippedCount = orders.where((o) => o.status.toLowerCase() == 'shipped').length;
            final deliveredCount = orders.where((o) =>
                o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').length;
            final unreadCount = notifications.where((n) => !n.isRead).length;
            final recentOrders = orders.take(5).toList();

            // Get user name
            final homeState = context.watch<HomeCubit>().state;
            final userName = homeState is HomeLoaded ? homeState.user?.fullName : null;

            return RefreshIndicator(
              onRefresh: () => context.read<CustomerCubit>().loadAll(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Header
                  _buildHeader(cs, userName),
                  const SizedBox(height: 16),

                  // Shop buttons
                  _buildShopButtons(cs),
                  const SizedBox(height: 20),

                  // Needs attention
                  _buildSectionTitle('Needs your attention', cs),
                  const SizedBox(height: 8),
                  _buildAttentionCard(cs, pendingCount, unreadCount),
                  const SizedBox(height: 20),

                  // Order journey
                  _buildSectionTitle('Your order journey', cs),
                  const SizedBox(height: 8),
                  _buildOrderJourney(cs, orders.length, pendingCount, processingCount + shippedCount, deliveredCount),
                  const SizedBox(height: 20),

                  // Quick stats
                  _buildQuickStats(cs, orders.length, addresses.length, paymentMethods.length),
                  const SizedBox(height: 20),

                  // Recent orders
                  if (recentOrders.isNotEmpty) ...[
                    _buildSectionRow('Recent orders', 'View all', cs, () =>
                        context.push(AppConstants.orderHistoryRoute)),
                    const SizedBox(height: 8),
                    ...recentOrders.map((o) => _buildRecentOrderItem(o, cs)),
                    const SizedBox(height: 20),
                  ],

                  // Quick actions
                  _buildSectionTitle('Quick actions', cs),
                  const SizedBox(height: 8),
                  _buildQuickActions(cs),
                  const SizedBox(height: 20),

                  // Account readiness
                  _buildSectionTitle('Account readiness', cs),
                  const SizedBox(height: 8),
                  _buildAccountReadiness(cs, addresses, paymentMethods),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, String? userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Xerin Market',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text('Welcome back, ${_firstName(userName)}',
          style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 2),
        Text('Track active orders and manage everything you buy.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35)),
        ),
      ],
    );
  }

  Widget _buildShopButtons(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push(AppConstants.exploreProductsRoute),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Shop Products'),
            style: ElevatedButton.styleFrom(elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppConstants.orderHistoryRoute),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('Track Orders'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _buildSectionRow(String title, String action, ColorScheme cs, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        GestureDetector(
          onTap: onTap,
          child: Text(action, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        ),
      ],
    );
  }

  Widget _buildAttentionCard(ColorScheme cs, int pendingCount, int unreadCount) {
    final totalActions = pendingCount + unreadCount;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$totalActions actions',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const Spacer(),
                if (totalActions > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$totalActions',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),
            _attentionRow(Icons.payment_outlined, 'Payment required',
              pendingCount > 0 ? 'Complete payment to keep your order moving' : 'No payment required',
              pendingCount, const Color(0xFFF59E0B), cs),
            const SizedBox(height: 12),
            _attentionRow(Icons.notifications_outlined, 'Unread notifications',
              'Order and delivery updates appear here',
              unreadCount, cs.primary, cs),
          ],
        ),
      ),
    );
  }

  Widget _attentionRow(IconData icon, String title, String desc, int count, Color color, ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(desc, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          )
        else
          Icon(Icons.check_circle, size: 16, color: cs.onSurface.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildOrderJourney(ColorScheme cs, int total, int pending, int active, int delivered) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('A quick view of where your purchases are',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                GestureDetector(
                  onTap: () => context.push(AppConstants.orderHistoryRoute),
                  child: Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _journeyStat('$total', 'All', const Color(0xFF6B7280), cs)),
                Expanded(child: _journeyStat('$pending', 'Payment', const Color(0xFFF59E0B), cs)),
                Expanded(child: _journeyStat('$active', 'Active', cs.primary, cs)),
                Expanded(child: _journeyStat('$delivered', 'Delivered', const Color(0xFF22C55E), cs)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _journeyStat(String count, String label, Color color, ColorScheme cs) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildQuickStats(ColorScheme cs, int orderCount, int addressCount, int paymentCount) {
    return Row(
      children: [
        Expanded(child: _statTile(Icons.receipt_long_outlined, '$orderCount', 'Orders', cs, () =>
            context.push(AppConstants.orderHistoryRoute))),
        const SizedBox(width: 8),
        Expanded(child: _statTile(Icons.location_on_outlined, '$addressCount', 'Addresses', cs, () =>
            context.push(AppConstants.addressesRoute))),
        const SizedBox(width: 8),
        Expanded(child: _statTile(Icons.credit_card_outlined, '$paymentCount', 'Payments', cs, () =>
            context.push(AppConstants.paymentMethodsRoute))),
      ],
    );
  }

  Widget _statTile(IconData icon, String count, String label, ColorScheme cs, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(height: 6),
              Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrderItem(OrderModel order, ColorScheme cs) {
    final color = _statusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(AppConstants.orderDetailRoute, extra: {'order': order}),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.orderRef}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(_formatDate(order.createdAt),
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(width: 6),
                        Text('· ${order.displayStatus}',
                          style: TextStyle(fontSize: 11, color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(order.formattedTotal,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme cs) {
    final actions = [
      _QuickAction(icon: Icons.shopping_cart_outlined, label: 'Checkout', route: AppConstants.checkoutRoute),
      _QuickAction(icon: Icons.favorite_outline, label: 'Wishlist', route: AppConstants.exploreProductsRoute),
      _QuickAction(icon: Icons.location_on_outlined, label: 'Addresses', route: AppConstants.addressesRoute),
      _QuickAction(icon: Icons.notifications_outlined, label: 'Notifications', route: AppConstants.notificationsRoute),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        return GestureDetector(
          onTap: () => context.push(a.route),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, size: 22, color: cs.primary),
                const SizedBox(height: 6),
                Text(a.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountReadiness(ColorScheme cs, List addresses, List paymentMethods) {
    final hasAddress = addresses.isNotEmpty;
    final hasDefaultAddress = addresses.any((a) => a.isDefault);
    final hasPayment = paymentMethods.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _readinessRow('Email verified', true, cs),
            _readinessRow('Delivery address added', hasAddress, cs),
            _readinessRow('Default address selected', hasDefaultAddress, cs),
            _readinessRow('Payment method added', hasPayment, cs),
          ],
        ),
      ),
    );
  }

  Widget _readinessRow(String label, bool ready, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: ready ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: ready ? 0.7 : 0.4))),
          const Spacer(),
          Text(ready ? 'Ready' : 'Pending',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: ready ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;

  const _QuickAction({required this.icon, required this.label, required this.route});
}
