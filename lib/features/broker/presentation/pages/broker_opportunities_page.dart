import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

class BrokerOpportunitiesPage extends StatefulWidget {
  const BrokerOpportunitiesPage({super.key});

  @override
  State<BrokerOpportunitiesPage> createState() => _BrokerOpportunitiesPageState();
}

class _BrokerOpportunitiesPageState extends State<BrokerOpportunitiesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    context.read<BrokerCubit>().loadOpportunities();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BrokerOpportunityModel> _filter(List<BrokerOpportunityModel> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((o) => o.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text('Broker marketplace'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: _mawingaPrimary,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.4),
              indicatorColor: _mawingaPrimary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Available'),
                Tab(text: 'My Promotions'),
              ],
            ),
          ]),
        ),
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerActionSuccess) {
            NotificationService().success(state.message);
          } else if (state is BrokerError) {
            NotificationService().error(state.message);
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerOpportunitiesLoaded) {
            return TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(context, _filter(state.opportunities), cs, isAccepted: false),
                _buildList(context, _filter(state.accepted), cs, isAccepted: true),
              ],
            );
          }
          if (state is BrokerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadOpportunities(),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<BrokerOpportunityModel> items,
    ColorScheme cs, {
    required bool isAccepted,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Uicons.box, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              isAccepted ? 'No active promotions yet.' : 'No opportunities available right now.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 4),
            Text(
              isAccepted
                  ? 'Accept campaigns from the Available tab to start promoting.'
                  : 'Check back later for new seller products to promote.',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3)),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('${items.length} ${items.length == 1 ? 'opportunity' : 'opportunities'}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
          );
        }
        final opp = items[index - 1];
        return _opportunityCard(context, opp, cs, isAccepted: isAccepted);
      },
    );
  }

  Widget _opportunityCard(BuildContext context, BrokerOpportunityModel opp, ColorScheme cs, {required bool isAccepted}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _mawingaPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: opp.productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(opp.productImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(Uicons.box, color: _mawingaPrimary, size: 22)),
                    )
                  : Icon(Uicons.box, color: _mawingaPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(opp.productName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Uicons.box, size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text('Stock available: ${opp.availableQuantity}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ]),
            ])),
            if (isAccepted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Accepted',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: _infoCol(cs, 'Customer price', '${opp.currency} ${opp.estimatedSellerNetPerUnit}', cs.onSurface)),
            Container(width: 1, height: 32, color: cs.onSurface.withValues(alpha: 0.06)),
            Expanded(child: _infoCol(cs, 'Your reward / unit', '${opp.currency} ${opp.estimatedRewardPerUnit}', _mawingaPrimary)),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(children: [
            Icon(Uicons.circleInfo, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Reward rule: ${opp.currency} ${opp.estimatedRewardPerUnit} · Campaign cap ${opp.availableQuantity} sales',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            )),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: isAccepted
              ? Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyReferralLink(context, opp),
                      icon: Icon(Uicons.copy, size: 16, color: _mawingaPrimary),
                      label: Text('Copy Referral Link',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mawingaPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _mawingaPrimary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.read<BrokerCubit>().stopOpportunity(opp.offerId),
                    icon: Icon(Uicons.minus, size: 16, color: const Color(0xFFEF4444)),
                    label: Text('Stop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ])
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.read<BrokerCubit>().acceptOpportunity(opp.offerId),
                    icon: const Icon(Uicons.check, size: 16),
                    label: const Text('Accept & Promote',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _mawingaPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _infoCol(ColorScheme cs, String label, String value, Color valueColor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
    ]);
  }

  Future<void> _copyReferralLink(BuildContext context, BrokerOpportunityModel opp) async {
    NotificationService().info('Generating referral link...');
    final result = await context.read<BrokerCubit>().getReferralLink(opp.offerId);
    if (result != null) {
      final link = result['share_path']?.toString() ?? '';
      final code = result['referral_code']?.toString() ?? '';
      final fullLink = link.isNotEmpty ? 'https://xerin.co$link' : 'https://xerin.co/r/$code';
      await Clipboard.setData(ClipboardData(text: fullLink));
      if (context.mounted) {
        NotificationService().success('Referral link copied to clipboard!');
      }
    }
  }
}
