import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/support_model.dart';
import '../../presentation/cubit/support_cubit.dart';
import '../../presentation/cubit/support_state.dart';

class SupportTicketDetailPage extends StatefulWidget {
  final String ticketId;

  const SupportTicketDetailPage({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadTicketDetail(widget.ticketId);
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();
    context.read<SupportCubit>().replyTicket(
          ticketId: widget.ticketId,
          message: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ticket Details'),
      ),
      body: SafeArea(
        child: BlocConsumer<SupportCubit, SupportState>(
          listener: (context, state) {
            if (state is SupportError) {
              NotificationService().error(state.message);
            }
            if (state is SupportMessageSent) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            if (state is SupportLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SupportTicketDetailLoaded ||
                state is SupportMessageSent) {
              final ticket = state is SupportTicketDetailLoaded
                  ? state.ticket
                  : (state as SupportMessageSent).ticket;
              return _buildBody(ticket, colorScheme);
            }
            return const Center(child: Text('Loading...'));
          },
        ),
      ),
    );
  }

  Widget _buildBody(SupportTicketModel ticket, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildTicketHeader(ticket, colorScheme),
        Expanded(
          child: ticket.messages.isEmpty
              ? _buildNoMessages(colorScheme)
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final msg = ticket.messages[index];
                    return _MessageBubble(message: msg);
                  },
                ),
        ),
        if (ticket.isOpen) _buildInputBar(colorScheme),
      ],
    );
  }

  Widget _buildTicketHeader(SupportTicketModel ticket, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(ticket.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(ticket.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ticket.ticketNumber,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
          if (ticket.description != null &&
              ticket.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ticket.description!,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoMessages(ColorScheme cs) {
    return Center(
      child: Text(
        'No messages yet. Start the conversation below.',
        style: TextStyle(
          fontSize: 14,
          color: cs.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Uicons.paperPlane),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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
        return Colors.blue;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final SupportTicketMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isStaff = message.isStaff;

    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isStaff
              ? cs.onSurface.withValues(alpha: 0.06)
              : cs.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isStaff ? Radius.zero : const Radius.circular(16),
            bottomRight: isStaff ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.senderName != null) ...[
              Text(
                message.senderName!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isStaff
                      ? cs.onSurface.withValues(alpha: 0.6)
                      : cs.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.message,
              style: TextStyle(
                fontSize: 14,
                color: isStaff ? cs.onSurface : cs.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isStaff
                    ? cs.onSurface.withValues(alpha: 0.4)
                    : cs.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
