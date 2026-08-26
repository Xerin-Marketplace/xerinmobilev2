import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/broker_models.dart';
import '../cubit/broker_cubit.dart';

class MawingaShareEarnPage extends StatefulWidget {
  const MawingaShareEarnPage({super.key});

  @override
  State<MawingaShareEarnPage> createState() => _MawingaShareEarnPageState();
}

class _MawingaShareEarnPageState extends State<MawingaShareEarnPage> {
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
        title: const Text('Share & Earn'),
      ),
      body: SafeArea(
        child: BlocConsumer<BrokerCubit, BrokerState>(
          listener: (context, state) {
            if (state is BrokerError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is BrokerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BrokerOpportunitiesLoaded) {
              final opportunities = state.opportunities
                  .where((o) => o.alreadyAccepted)
                  .toList();
              if (opportunities.isEmpty) {
                return _buildEmpty(cs);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  final opp = opportunities[index];
                  return _buildProductShareCard(context, opp, cs);
                },
              );
            }
            return _buildEmpty(cs);
          },
        ),
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
            Icon(Uicons.share, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No products to share yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Accept opportunities from the Find Products page to start sharing and earning.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push(AppConstants.mawingaFindProductsRoute),
              icon: const Icon(Uicons.search, size: 18),
              label: const Text('Find Products to Sell'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductShareCard(BuildContext context, BrokerOpportunityModel opp, ColorScheme cs) {
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
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: cs.onSurface.withValues(alpha: 0.05),
                        child: Icon(Uicons.box, size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Uicons.box, size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
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
                      const SizedBox(height: 4),
                      Text(
                        'Commission: ${opp.estimatedRewardPerUnit} ${opp.currency}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
              Expanded(
                child: OutlinedButton.icon(
              onPressed: () => _loadReferralAndShare(context, opp),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Uicons.share, size: 16),
              label: const Text('Share & Earn'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _loadReferralAndCopy(context, opp),
              icon: const Icon(Uicons.copy, size: 18),
              tooltip: 'Copy link',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadReferralAndShare(BuildContext context, BrokerOpportunityModel opp) async {
    final cubit = context.read<BrokerCubit>();
    final result = await cubit.getReferralLink(opp.offerId);
    if (result != null && context.mounted) {
      final link = result['share_path']?.toString() ?? '';
      final code = result['referral_code']?.toString() ?? '';
      final fullLink = link.isNotEmpty ? 'https://xerin.co$link' : 'https://xerin.co/r/$code';
      final shareText = 'Check out ${opp.productName} on Xerin Marketplace! '
          'Commission earned: ${opp.estimatedRewardPerUnit} ${opp.currency}\n$fullLink';

      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        NotificationService().success('Share link copied! Paste it in WhatsApp, Instagram, TikTok or Facebook.');
        _showShareSheet(context, opp, fullLink);
      }
    }
  }

  void _loadReferralAndCopy(BuildContext context, BrokerOpportunityModel opp) async {
    final cubit = context.read<BrokerCubit>();
    final result = await cubit.getReferralLink(opp.offerId);
    if (result != null && context.mounted) {
      final link = result['share_path']?.toString() ?? '';
      final code = result['referral_code']?.toString() ?? '';
      final fullLink = link.isNotEmpty ? 'https://xerin.co$link' : 'https://xerin.co/r/$code';
      await Clipboard.setData(ClipboardData(text: fullLink));
      if (context.mounted) {
        NotificationService().success('Link copied to clipboard');
      }
    }
  }

  void _showShareSheet(BuildContext context, BrokerOpportunityModel opp, String link) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Share ${opp.productName} and earn ${opp.estimatedRewardPerUnit} ${opp.currency} per sale',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareButton(ctx, 'WhatsApp', Uicons.comment, const Color(0xFF25D366), link),
                _shareButton(ctx, 'Instagram', Uicons.camera, const Color(0xFFE1306C), link),
                _shareButton(ctx, 'TikTok', Uicons.music, const Color(0xFF000000), link),
                _shareButton(ctx, 'Facebook', Uicons.globe, const Color(0xFF1877F2), link),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Uicons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      NotificationService().success('Copied!');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _shareButton(BuildContext ctx, String label, IconData icon, Color color, String link) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        NotificationService().success('$label share link copied! Open $label and paste.');
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
