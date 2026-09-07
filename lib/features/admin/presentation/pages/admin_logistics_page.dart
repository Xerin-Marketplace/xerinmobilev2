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
      return Center(child: Text('No logistics companies', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))));
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface))),
            _statusBadge(cs, status),
          ]),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(phone, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (country.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Country: $country', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (zones.isNotEmpty || services.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (zones.isNotEmpty) Text('Zones: $zones', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              if (zones.isNotEmpty && services.isNotEmpty) const SizedBox(width: 12),
              if (services.isNotEmpty) Text('Services: $services', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ]),
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
