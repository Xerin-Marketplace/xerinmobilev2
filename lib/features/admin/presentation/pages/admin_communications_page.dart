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
      body: _body(cs),
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
      return Center(child: Text('No notification templates', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))));
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

  Widget _templateTile(ColorScheme cs, Map<String, dynamic> t) {
    final name = t['name']?.toString() ?? 'Untitled';
    final channel = t['channel']?.toString() ?? t['type']?.toString() ?? '';
    final subject = t['subject']?.toString() ?? '';
    final body = t['body']?.toString() ?? t['content']?.toString() ?? '';
    final active = t['is_active'] == true || t['active'] == true;

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
        ]),
      ),
    );
  }
}
