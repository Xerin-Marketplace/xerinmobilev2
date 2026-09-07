import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminCommunicationsPage extends StatefulWidget {
  const AdminCommunicationsPage({super.key});

  @override
  State<AdminCommunicationsPage> createState() => _AdminCommunicationsPageState();
}

class _AdminCommunicationsPageState extends State<AdminCommunicationsPage> {
  final _ds = sl<AdminRemoteDataSource>();
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  String? _error;

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
      final templates = await _ds.getNotificationTemplates();
      setState(() {
        _templates = templates;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _countChannel(String channel) =>
      _templates.where((t) => (t['channel']?.toString() ?? t['type']?.toString() ?? '') == channel).length;
  int _countActive() =>
      _templates.where((t) => t['is_active'] == true || t['active'] == true).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Communications'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        if (!_loading && _error == null) _summaryRow(cs),
        Expanded(child: _body(cs)),
      ]),
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
    if (_templates.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Uicons.bell, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No notification templates', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _templates.length,
        itemBuilder: (context, i) => _templateTile(cs, _templates[i]),
      ),
    );
  }

  Widget _summaryRow(ColorScheme cs) {
    final total = _templates.length;
    final active = _countActive();
    final inactive = total - active;
    final sms = _countChannel('sms');
    final email = _countChannel('email');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _statBox(cs, 'Total', total, cs.primary),
        const SizedBox(width: 8),
        _statBox(cs, 'Active', active, Colors.green),
        const SizedBox(width: 8),
        _statBox(cs, 'Inactive', inactive, Colors.grey),
        const SizedBox(width: 8),
        _statBox(cs, 'SMS', sms, Colors.blue),
        const SizedBox(width: 8),
        _statBox(cs, 'Email', email, Colors.orange),
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
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }

  Widget _templateTile(ColorScheme cs, Map<String, dynamic> t) {
    final name = t['name']?.toString() ?? 'Untitled';
    final channel = t['channel']?.toString() ?? t['type']?.toString() ?? '';
    final subject = t['subject']?.toString() ?? '';
    final body = t['body']?.toString() ?? t['content']?.toString() ?? '';
    final active = t['is_active'] == true || t['active'] == true;
    final trigger = t['trigger']?.toString() ?? t['event']?.toString() ?? '';
    final lastSent = t['last_sent_at']?.toString() ?? t['last_used']?.toString() ?? '';
    final sentCount = t['sent_count']?.toString() ?? t['total_sent']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface))),
            if (channel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(channel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary)),
              ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (active ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(active ? 'Active' : 'Inactive',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.green : Colors.grey)),
            ),
          ]),
          if (subject.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subject, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (trigger.isNotEmpty || sentCount.isNotEmpty || lastSent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (trigger.isNotEmpty) ...[
                Icon(Icons.flash_on, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(trigger, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(width: 12),
              ],
              if (sentCount.isNotEmpty) ...[
                Icon(Icons.send, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text('$sentCount sent', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ]),
            if (lastSent.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Last sent: ${lastSent.substring(0, lastSent.length > 10 ? 10 : lastSent.length)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
            ],
          ],
        ]),
      ),
    );
  }
}
