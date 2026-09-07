import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminPromotionsPage extends StatefulWidget {
  const AdminPromotionsPage({super.key});

  @override
  State<AdminPromotionsPage> createState() => _AdminPromotionsPageState();
}

class _AdminPromotionsPageState extends State<AdminPromotionsPage> {
  final _ds = sl<AdminRemoteDataSource>();
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final campaigns = await _ds.getAdminCampaigns(status: _statusFilter);
      setState(() {
        _campaigns = campaigns;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _countStatus(String status) =>
      _campaigns.where((c) => (c['status']?.toString() ?? '') == status).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Promotions'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        if (!_loading && _error == null) _summaryRow(cs),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('All', null),
              _chip('Active', 'active'),
              _chip('Scheduled', 'scheduled'),
              _chip('Expired', 'expired'),
              _chip('Paused', 'paused'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _body(cs)),
      ]),
    );
  }

  Widget _summaryRow(ColorScheme cs) {
    final total = _campaigns.length;
    final active = _countStatus('active');
    final scheduled = _countStatus('scheduled');
    final expired = _countStatus('expired');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _statBox(cs, 'Total', total, cs.primary),
        const SizedBox(width: 8),
        _statBox(cs, 'Active', active, Colors.green),
        const SizedBox(width: 8),
        _statBox(cs, 'Scheduled', scheduled, Colors.blue),
        const SizedBox(width: 8),
        _statBox(cs, 'Expired', expired, Colors.red),
      ]),
    );
  }

  Widget _statBox(ColorScheme cs, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _load();
        },
      ),
    );
  }

  Widget _body(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('Retry')),
      ]));
    }
    if (_campaigns.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Uicons.gift, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No promotions found', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _campaigns.length,
        itemBuilder: (context, i) => _campaignTile(cs, _campaigns[i]),
      ),
    );
  }

  Widget _campaignTile(ColorScheme cs, Map<String, dynamic> c) {
    final name = c['name']?.toString() ?? c['title']?.toString() ?? 'Untitled';
    final status = c['status']?.toString() ?? 'unknown';
    final discountType = c['discount_type']?.toString() ?? c['type']?.toString() ?? '';
    final discountValue = c['discount_value']?.toString() ?? c['value']?.toString() ?? '';
    final startDate = c['start_date']?.toString() ?? '';
    final endDate = c['end_date']?.toString() ?? '';
    final budget = c['budget']?.toString() ?? '';
    final spent = c['spent']?.toString() ?? c['total_spent']?.toString() ?? '';
    final usageCount = c['usage_count']?.toString() ?? c['used_count']?.toString() ?? '';
    final maxUsage = c['max_usage']?.toString() ?? c['usage_limit']?.toString() ?? '';
    final code = c['code']?.toString() ?? c['coupon_code']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface))),
            _statusBadge(cs, status),
          ]),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Text('Code: $code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          ],
          if (discountType.isNotEmpty || discountValue.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Discount: $discountType ${discountValue.isNotEmpty ? '($discountValue)' : ''}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (startDate.isNotEmpty)
                Text('From: ${startDate.substring(0, startDate.length > 10 ? 10 : startDate.length)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              if (startDate.isNotEmpty && endDate.isNotEmpty) const SizedBox(width: 12),
              if (endDate.isNotEmpty)
                Text('To: ${endDate.substring(0, endDate.length > 10 ? 10 : endDate.length)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ]),
          ],
          if (budget.isNotEmpty || spent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (budget.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('Budget: $budget', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
              if (budget.isNotEmpty && spent.isNotEmpty) const SizedBox(width: 8),
              if (spent.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('Spent: $spent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                ),
            ]),
          ],
          if (usageCount.isNotEmpty || maxUsage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Usage: $usageCount${maxUsage.isNotEmpty ? ' / $maxUsage' : ''}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ]),
      ),
    );
  }

  Widget _statusBadge(ColorScheme cs, String status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'expired'
            ? Colors.red
            : status == 'paused'
                ? Colors.orange
                : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
