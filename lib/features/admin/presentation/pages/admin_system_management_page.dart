import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/datasources/admin_remote_datasource.dart';

class AdminSystemManagementPage extends StatefulWidget {
  const AdminSystemManagementPage({super.key});

  @override
  State<AdminSystemManagementPage> createState() => _AdminSystemManagementPageState();
}

class _AdminSystemManagementPageState extends State<AdminSystemManagementPage> {
  final _ds = sl<AdminRemoteDataSource>();
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _securityEvents = [];
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
      final results = await Future.wait([
        _ds.getAuditLogs(),
        _ds.getSecurityEvents(),
      ]);
      setState(() {
        _auditLogs = results[0];
        _securityEvents = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _countSeverity(String severity) =>
      _securityEvents.where((e) => (e['severity']?.toString() ?? 'low') == severity).length;
  int _countUnresolved() =>
      _securityEvents.where((e) => e['resolved'] != true && e['is_resolved'] != true).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Uicons.angleLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('System Management'),
          actions: [
            IconButton(
              icon: const Icon(Uicons.refresh, size: 20),
              onPressed: _load,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Audit Logs'),
              Tab(text: 'Security Events'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ]))
                : Column(children: [
                    _summaryRow(cs),
                    Expanded(child: TabBarView(children: [
                      _auditLogsView(cs),
                      _securityEventsView(cs),
                    ])),
                  ]),
      ),
    );
  }

  Widget _summaryRow(ColorScheme cs) {
    final totalLogs = _auditLogs.length;
    final totalEvents = _securityEvents.length;
    final critical = _countSeverity('critical');
    final unresolved = _countUnresolved();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        _statBox(cs, 'Audit Logs', totalLogs, cs.primary),
        const SizedBox(width: 8),
        _statBox(cs, 'Security Events', totalEvents, Colors.blue),
        const SizedBox(width: 8),
        _statBox(cs, 'Critical', critical, Colors.red),
        const SizedBox(width: 8),
        _statBox(cs, 'Unresolved', unresolved, Colors.orange),
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
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }

  Widget _auditLogsView(ColorScheme cs) {
    if (_auditLogs.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Uicons.clock, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No audit logs', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _auditLogs.length,
        itemBuilder: (context, i) => _auditTile(cs, _auditLogs[i]),
      ),
    );
  }

  Widget _auditTile(ColorScheme cs, Map<String, dynamic> log) {
    final action = log['action']?.toString() ?? '';
    final actor = log['actor']?.toString() ?? log['user']?.toString() ?? log['user_id']?.toString() ?? '';
    final resource = log['resource']?.toString() ?? log['entity']?.toString() ?? '';
    final timestamp = log['created_at']?.toString() ?? log['timestamp']?.toString() ?? '';
    final ip = log['ip_address']?.toString() ?? log['ip']?.toString() ?? '';
    final details = log['details']?.toString() ?? log['metadata']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(action, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 4),
          if (actor.isNotEmpty)
            Text('Actor: $actor', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          if (resource.isNotEmpty)
            Text('Resource: $resource', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          if (ip.isNotEmpty)
            Text('IP: $ip', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          if (timestamp.isNotEmpty)
            Text(timestamp, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(details, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ]),
      ),
    );
  }

  Widget _securityEventsView(ColorScheme cs) {
    if (_securityEvents.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Uicons.shield, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No security events', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _securityEvents.length,
        itemBuilder: (context, i) => _securityTile(cs, _securityEvents[i]),
      ),
    );
  }

  Widget _securityTile(ColorScheme cs, Map<String, dynamic> e) {
    final type = e['event_type']?.toString() ?? e['type']?.toString() ?? 'Event';
    final severity = e['severity']?.toString() ?? 'low';
    final description = e['description']?.toString() ?? e['message']?.toString() ?? '';
    final resolved = e['resolved'] == true || e['is_resolved'] == true;
    final timestamp = e['created_at']?.toString() ?? e['timestamp']?.toString() ?? '';
    final source = e['source']?.toString() ?? e['source_ip']?.toString() ?? '';
    final user = e['user']?.toString() ?? e['user_id']?.toString() ?? '';

    final color = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(type, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(severity, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (resolved ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(resolved ? 'Resolved' : 'Open',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: resolved ? Colors.green : Colors.orange)),
            ),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ],
          if (user.isNotEmpty || source.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              if (user.isNotEmpty) ...[
                Icon(Icons.person, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(user, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(width: 12),
              ],
              if (source.isNotEmpty) ...[
                Icon(Icons.computer, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(source, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ]),
          ],
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(timestamp, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        ]),
      ),
    );
  }
}
