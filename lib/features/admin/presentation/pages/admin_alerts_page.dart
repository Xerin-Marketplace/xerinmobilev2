import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminAlertsPage extends StatefulWidget {
  const AdminAlertsPage({super.key});

  @override
  State<AdminAlertsPage> createState() => _AdminAlertsPageState();
}

class _AdminAlertsPageState extends State<AdminAlertsPage> {
  String _filter = 'all'; // all, unresolved, resolved

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All', 'all'),
            _filterChip('Unresolved', 'unresolved'),
            _filterChip('Resolved', 'resolved'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) {
          setState(() => _filter = value);
          final resolved = value == 'resolved'
              ? true
              : value == 'unresolved'
                  ? false
                  : null;
          context.read<AdminCubit>().loadAlerts(resolved: resolved);
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        }
        if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminAlertsLoaded) {
          if (state.alerts.isEmpty) {
            return const Center(child: Text('No alerts found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.alerts.length,
            itemBuilder: (context, index) =>
                _alertCard(context, state.alerts[index]),
          );
        }
        if (state is AdminError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Uicons.exclamationTriangle, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AdminCubit>().loadAlerts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('Loading...'));
      },
    );
  }

  Widget _alertCard(BuildContext context, AdminSystemAlertModel alert) {
    final color = alert.severity == 'critical'
        ? Colors.red
        : alert.severity == 'warning'
            ? Colors.orange
            : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Uicons.bell, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(alert.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (alert.isResolved)
                  const Icon(Uicons.checkCircle, size: 18, color: Colors.green)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(alert.severity.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.message, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(alert.alertType,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (alert.createdAt != null)
                  Text(alert.createdAt!.substring(0, 10),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (!alert.isResolved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Uicons.checkCircle, size: 16),
                  label: const Text('Resolve'),
                  onPressed: () => context.read<AdminCubit>().resolveAlert(alert.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
