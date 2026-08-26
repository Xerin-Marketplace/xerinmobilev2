import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/broker_models.dart';
import '../../data/models/mawinga_models.dart';
import '../cubit/broker_cubit.dart';

class MawingaFindProductsPage extends StatefulWidget {
  const MawingaFindProductsPage({super.key});

  @override
  State<MawingaFindProductsPage> createState() => _MawingaFindProductsPageState();
}

class _MawingaFindProductsPageState extends State<MawingaFindProductsPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadOpportunities();
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
        title: const Text('Find Products to Sell'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryFilter(cs),
            Expanded(
              child: BlocConsumer<BrokerCubit, BrokerState>(
                listener: (context, state) {
                  if (state is BrokerError) {
                    NotificationService().error(state.message);
                  }
                  if (state is BrokerActionSuccess) {
                    NotificationService().success(state.message);
                  }
                },
                builder: (context, state) {
                  if (state is BrokerLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BrokerOpportunitiesLoaded) {
                    final opportunities = state.opportunities;
                    if (opportunities.isEmpty) {
                      return _buildEmpty(cs);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: opportunities.length,
                      itemBuilder: (context, index) {
                        final opp = opportunities[index];
                        return _buildProductCard(context, opp, cs);
                      },
                    );
                  }
                  return _buildEmpty(cs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(ColorScheme cs) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _filterChip('All', null, cs),
          ...MawingaProductCategory.categories.map((cat) =>
            _filterChip(cat.name, cat.name, cs),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, ColorScheme cs) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
        },
        selectedColor: cs.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.search, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No products available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'New products from suppliers and merchants will appear here. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, BrokerOpportunityModel opp, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (opp.productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      opp.productImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: cs.onSurface.withValues(alpha: 0.05),
                        child: Icon(Uicons.box, size: 32, color: cs.onSurface.withValues(alpha: 0.2)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Uicons.box, size: 32, color: cs.onSurface.withValues(alpha: 0.2)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opp.productName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _infoRow('Your earnings', '${opp.estimatedRewardPerUnit} ${opp.currency}', cs.primary),
                      const SizedBox(height: 2),
                      _infoRow('Stock available', '${opp.availableQuantity} units', cs.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (opp.alreadyAccepted) ...[
                  Icon(Uicons.checkCircle, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Already accepted',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push(AppConstants.mawingaShareEarnRoute),
                    icon: Icon(Uicons.share, size: 16),
                    label: const Text('Share'),
                  ),
                ] else ...[
                  Icon(Uicons.circleInfo, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      opp.isActive ? 'Active campaign' : 'Inactive',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: opp.isActive
                        ? () => _acceptOpportunity(context, opp.offerId)
                        : null,
                    icon: Icon(Uicons.plus, size: 16),
                    label: const Text('Sell This'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.6))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  void _acceptOpportunity(BuildContext context, String offerId) {
    context.read<BrokerCubit>().acceptOpportunity(offerId);
  }
}
