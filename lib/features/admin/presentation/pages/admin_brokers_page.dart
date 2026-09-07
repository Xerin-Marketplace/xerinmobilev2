import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminBrokersPage extends StatefulWidget {
  const AdminBrokersPage({super.key});

  @override
  State<AdminBrokersPage> createState() => _AdminBrokersPageState();
}

class _AdminBrokersPageState extends State<AdminBrokersPage> {
  final _ds = sl<AdminRemoteDataSource>();
  List<Map<String, dynamic>> _brokers = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  final _searchCtrl = TextEditingController();

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
      final brokers = await _ds.getAdminBrokers(
        status: _statusFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      setState(() {
        _brokers = brokers;
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
        title: const Text('Brokers'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search brokers...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('All', null),
              _chip('Pending', 'pending'),
              _chip('Under Review', 'under_review'),
              _chip('Approved', 'approved'),
              _chip('Rejected', 'rejected'),
              _chip('Suspended', 'suspended'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _body(cs)),
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
    if (_brokers.isEmpty) {
      return Center(child: Text('No brokers found', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _brokers.length,
        itemBuilder: (context, i) => _brokerTile(cs, _brokers[i]),
      ),
    );
  }

  Widget _brokerTile(ColorScheme cs, Map<String, dynamic> b) {
    final name = b['full_name']?.toString() ?? b['name']?.toString() ?? 'Unknown';
    final email = b['email']?.toString() ?? '';
    final phone = b['phone_number']?.toString() ?? '';
    final status = b['status']?.toString() ?? b['kyc_status']?.toString() ?? 'unknown';
    final nida = b['nida_number']?.toString() ?? '';
    final brokerId = b['id']?.toString() ?? '';

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
          if (nida.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('NIDA: $nida', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (status == 'pending' || status == 'under_review') ...[
            const SizedBox(height: 10),
            Row(children: [
              TextButton(
                onPressed: () async {
                  await _ds.approveBroker(brokerId);
                  _load();
                },
                child: const Text('Approve'),
              ),
              TextButton(
                onPressed: () async {
                  await _ds.rejectBroker(brokerId);
                  _load();
                },
                child: const Text('Reject', style: TextStyle(color: Colors.red)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _statusBadge(ColorScheme cs, String status) {
    final color = status == 'approved'
        ? Colors.green
        : status == 'rejected' || status == 'suspended'
            ? Colors.red
            : status == 'pending'
                ? Colors.orange
                : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
