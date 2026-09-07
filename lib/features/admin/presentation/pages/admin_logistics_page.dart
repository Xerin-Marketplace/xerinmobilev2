import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminLogisticsPage extends StatefulWidget {
  const AdminLogisticsPage({super.key});

  @override
  State<AdminLogisticsPage> createState() => _AdminLogisticsPageState();
}

class _AdminLogisticsPageState extends State<AdminLogisticsPage> {
  final _ds = sl<AdminRemoteDataSource>();
  List<Map<String, dynamic>> _companies = [];
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
      final companies = await _ds.getLogisticsCompanies(status: _statusFilter);
      setState(() {
        _companies = companies;
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
      _companies.where((c) => (c['status']?.toString() ?? '') == status).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Logistics'),
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
              _chip('Pending', 'pending'),
              _chip('Suspended', 'suspended'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _body(cs)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push(AppConstants.logisticsDashboardRoute),
              child: const Text('Open Logistics Panel'),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _summaryRow(ColorScheme cs) {
    final total = _companies.length;
    final active = _countStatus('active');
    final pending = _countStatus('pending');
    final suspended = _countStatus('suspended');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _statBox(cs, 'Total', total, cs.primary),
        const SizedBox(width: 8),
        _statBox(cs, 'Active', active, Colors.green),
        const SizedBox(width: 8),
        _statBox(cs, 'Pending', pending, Colors.orange),
        const SizedBox(width: 8),
        _statBox(cs, 'Suspended', suspended, Colors.red),
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
    if (_companies.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Uicons.truck, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No logistics companies', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _companies.length,
        itemBuilder: (context, i) => _companyTile(cs, _companies[i]),
      ),
    );
  }

  Widget _companyTile(ColorScheme cs, Map<String, dynamic> c) {
    final name = c['name']?.toString() ?? 'Unknown';
    final status = c['status']?.toString() ?? 'unknown';
    final email = c['email']?.toString() ?? c['admin_email']?.toString() ?? '';
    final phone = c['phone']?.toString() ?? c['contact_phone']?.toString() ?? '';
    final country = c['country']?.toString() ?? '';
    final zones = c['zones_count']?.toString() ?? c['zones']?.toString() ?? '';
    final services = c['services_count']?.toString() ?? c['services']?.toString() ?? '';
    final shipments = c['shipments_count']?.toString() ?? c['total_shipments']?.toString() ?? '';
    final rating = c['rating']?.toString() ?? c['performance_score']?.toString() ?? '';
    final createdAt = c['created_at']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text(name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
              if (country.isNotEmpty)
                Text(country, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ])),
            _statusBadge(cs, status),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (email.isNotEmpty) ...[
              Icon(Icons.email, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(email, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ]),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.phone, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(phone, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ]),
          ],
          if (zones.isNotEmpty || services.isNotEmpty || shipments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (zones.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('$zones zones', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              if (services.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('$services services', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                ),
              if (shipments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('$shipments shipments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                ),
              if (rating.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('Rating: $rating', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber)),
                ),
            ]),
          ],
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Joined: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ]),
      ),
    );
  }

  Widget _statusBadge(ColorScheme cs, String status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'suspended'
            ? Colors.red
            : status == 'pending'
                ? Colors.orange
                : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
