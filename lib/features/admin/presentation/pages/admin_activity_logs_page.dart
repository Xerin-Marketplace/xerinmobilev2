import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminActivityLogsPage extends StatefulWidget {
  const AdminActivityLogsPage({super.key});

  @override
  State<AdminActivityLogsPage> createState() => _AdminActivityLogsPageState();
}

class _AdminActivityLogsPageState extends State<AdminActivityLogsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadActivityLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadActivityLogs(),
          ),
        ],
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminActivityLogsLoaded) {
            if (state.logs.isEmpty) {
              return const Center(child: Text('No activity logs found'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              itemBuilder: (context, index) =>
                  _logCard(context, state.logs[index]),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCubit>().loadActivityLogs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  Widget _logCard(BuildContext context, AdminActivityLogModel log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(Uicons.clock, size: 18, color: Colors.blue),
        ),
        title: Text(log.action,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (log.resourceType != null)
              Text('Type: ${log.resourceType}', style: const TextStyle(fontSize: 12)),
            if (log.resourceId != null)
              Text('ID: ${log.resourceId!.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 12)),
            if (log.details != null)
              Text(log.details!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (log.createdAt != null)
              Text(log.createdAt!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
