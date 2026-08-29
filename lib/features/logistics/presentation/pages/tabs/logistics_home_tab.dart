import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/uicons.dart';
import '../../cubit/logistics_cubit.dart';
import '../../cubit/logistics_state.dart';

class LogisticsHomeTab extends StatelessWidget {
  final LogisticsDashboardLoaded dashboardState;

  const LogisticsHomeTab({super.key, required this.dashboardState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = dashboardState.dashboard;
    final a = dashboardState.account;

    return RefreshIndicator(
      onRefresh: () => context.read<LogisticsCubit>().loadDashboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XERIN LOGISTICS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.company.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _badge(a.memberRole.replaceAll('_', ' '),
                          Colors.white, cs.primary),
                      const SizedBox(width: 8),
                      _badge(a.company.status ?? 'Active', Colors.white70,
                          Colors.transparent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final stats = [
                  ('Total Shipments', d.shipmentsTotal, Uicons.truckBox),
                  ('Pickup Jobs', d.pickupJobsTotal, Uicons.box),
                  ('Active Zones', d.activeZones, Uicons.mapMarker),
                  ('Team Members', d.members, Uicons.users),
                ];
                final (label, value, icon) = stats[index];
                return _statCard(cs, label, value, icon);
              },
            ),
            const SizedBox(height: 20),
            _statusSection(cs, 'Shipments by Status', d.shipmentsByStatus),
            const SizedBox(height: 16),
            _statusSection(cs, 'Pickup Jobs by Status', d.pickupJobsByStatus),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _signalCard(
                      cs, 'Active Services', d.activeServices, Uicons.bolt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _signalCard(cs, 'Webhook Events (24h)',
                      d.webhookEvents24h, Uicons.bolt),
                ),
              ],
            ),
            if (d.webhookFailures24h > 0) ...[
              const SizedBox(height: 12),
              _signalCard(cs, 'Webhook Failures (24h)',
                  d.webhookFailures24h, Uicons.circleExclamation,
                  warning: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _statCard(
      ColorScheme cs, String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.5))),
              Icon(icon, size: 20, color: cs.primary),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _statusSection(
      ColorScheme cs, String title, Map<String, int> values) {
    final entries = values.entries.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text('No activity yet.',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)))
          else
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.replaceAll('_', ' '),
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.6))),
                      Text(e.value.toString(),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _signalCard(
      ColorScheme cs, String label, int value, IconData icon,
      {bool warning = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: warning ? Colors.red : cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                Text(value.toString(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
