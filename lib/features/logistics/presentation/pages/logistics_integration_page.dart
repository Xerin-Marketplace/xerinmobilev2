import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/logistics_cubit.dart';
import '../../presentation/cubit/logistics_state.dart';

class LogisticsIntegrationPage extends StatefulWidget {
  const LogisticsIntegrationPage({super.key});

  @override
  State<LogisticsIntegrationPage> createState() =>
      _LogisticsIntegrationPageState();
}

class _LogisticsIntegrationPageState extends State<LogisticsIntegrationPage> {
  @override
  void initState() {
    super.initState();
    context.read<LogisticsCubit>().loadIntegration();
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
        title: const Text('Integration'),
      ),
      body: SafeArea(
        child: BlocConsumer<LogisticsCubit, LogisticsState>(
          listener: (context, state) {
            if (state is LogisticsError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is LogisticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LogisticsIntegrationLoaded) {
              return _buildContent(state.integration.apiKey,
                  state.integration.webhookUrl, state.webhookEvents, cs);
            }
            return Center(
              child: Text('Loading...',
                  style:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(String? apiKey, String? webhookUrl,
      List<Map<String, dynamic>> events, ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () => context.read<LogisticsCubit>().loadIntegration(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('API Credentials',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API Key',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            apiKey ?? 'Not configured',
                            style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: apiKey != null
                                    ? cs.onSurface
                                    : cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        ),
                        if (apiKey != null)
                          IconButton(
                            icon: const Icon(Uicons.copy, size: 16),
                            onPressed: () {},
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Webhook URL',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    Text(
                      webhookUrl ?? 'Not configured',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: webhookUrl != null
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent Webhook Events',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Text('No webhook events',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4)))
            else
              ...events.map((e) => _EventCard(e, cs)),
          ],
        ),
      ),
    );
  }

  Widget _EventCard(Map<String, dynamic> event, ColorScheme cs) {
    final eventType = event['event_type']?.toString() ?? '';
    final status = event['status']?.toString() ?? '';
    final createdAt = event['created_at']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(eventType,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text(createdAt,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == 'success'
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: status == 'success' ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }
}
