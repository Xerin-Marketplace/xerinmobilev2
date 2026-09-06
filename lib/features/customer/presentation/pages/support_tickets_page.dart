import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../data/models/support_model.dart';
import '../../presentation/cubit/support_cubit.dart';
import '../../presentation/cubit/support_state.dart';

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadMyTickets();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/support-ticket-create'),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<SupportCubit, SupportState>(
          listener: (context, state) {
            if (state is SupportError) {
              NotificationService().error(state.message);
            }
          },
          builder: (context, state) {
            if (state is SupportLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SupportTicketsLoaded) {
              if (state.tickets.isEmpty) {
                return _buildEmptyState(colorScheme);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<SupportCubit>().loadMyTickets(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _TicketCard(ticket: state.tickets[index]),
                ),
              );
            }
            return _buildEmptyState(colorScheme);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/support-ticket-create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Need help? Create a support ticket and our team will assist you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/support-ticket-create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;

  const _TicketCard({required this.ticket});

  Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return cs.primary;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.push('/support-ticket-detail', extra: {
          'ticketId': ticket.id,
        }),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ticket.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(ticket.status, colorScheme),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _priorityColor(ticket.priority),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ticket.ticketNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.subject,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (ticket.description != null &&
                  ticket.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ticket.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  if (ticket.messages.isNotEmpty) ...[
                    const Spacer(),
                    Icon(Icons.chat_bubble_outline,
                        size: 14,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(
                      '${ticket.messages.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
