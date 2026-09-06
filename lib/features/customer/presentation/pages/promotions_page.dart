import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/promotion_cubit.dart';
import '../../data/models/promotion_model.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PromotionCubit>().loadAvailablePromotions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions & Deals')),
      body: BlocBuilder<PromotionCubit, PromotionState>(
        builder: (context, state) {
          if (state is PromotionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PromotionError) {
            return Center(child: Text(state.message));
          }
          if (state is PromotionsLoaded) {
            if (state.promotions.isEmpty) {
              return const Center(child: Text('No active promotions'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.promotions.length,
              itemBuilder: (context, index) {
                return _PromotionCard(promotion: state.promotions[index]);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promotion;

  const _PromotionCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final discountText = promotion.promotionType == 'percentage'
        ? '${promotion.discountValue.toStringAsFixed(0)}% OFF'
        : promotion.promotionType == 'free_shipping'
            ? 'FREE SHIPPING'
            : '${promotion.discountValue.toStringAsFixed(0)} OFF';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discountText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${promotion.code}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                  ),
                  if (promotion.endsAt != null)
                    Text(
                      'Valid until ${promotion.endsAt!.substring(0, 10)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  if (promotion.minimumOrderAmount != null)
                    Text(
                      'Min order: ${promotion.minimumOrderAmount!.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
