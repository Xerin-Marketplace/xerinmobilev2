import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../cubit/notification_cubit.dart';
import '../../data/models/notification_model.dart';
import '../../../../core/theme/uicons.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCubit>().loadNotifications();
    });
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order': return Uicons.shoppingBag;
      case 'promo': return Uicons.hashtag;
      case 'payment': return Uicons.creditCard;
      case 'system': return Uicons.circleInfo;
      default: return Uicons.bell;
    }
  }

  Color _typeColor(String type, ColorScheme cs) {
    switch (type) {
      case 'order': return const Color(0xFF3B82F6);
      case 'promo': return const Color(0xFFF59E0B);
      case 'payment': return const Color(0xFF22C55E);
      case 'system': return cs.primary;
      default: return cs.onSurface.withValues(alpha: 0.5);
    }
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> all) {
    if (!_showUnreadOnly) return all;
    return all.where((n) => !n.isRead).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final allNotifications = state is NotificationLoaded ? state.notifications : <NotificationModel>[];
            final isLoading = state is NotificationLoading;
            final isError = state is NotificationError;
            final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
            final notifications = _filterNotifications(allNotifications);

            return Column(
              children: [
                _buildHeader(colorScheme, allNotifications, unreadCount),
                if (allNotifications.isNotEmpty) _buildFilterChip(colorScheme),
                const SizedBox(height: 8),
                if (isLoading)
                  _buildLoadingState(colorScheme)
                else if (isError)
                  _buildErrorState(colorScheme, state.message)
                else if (notifications.isEmpty)
                  _buildEmptyState(colorScheme, _showUnreadOnly)
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildDismissibleNotification(notification, colorScheme, isDark);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, List<NotificationModel> all, int unreadCount) {
    final hasUnread = unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text('Notifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$unreadCount',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasUnread)
            GestureDetector(
              onTap: () => context.read<NotificationCubit>().markAllAsRead(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Uicons.checkCircle, size: 14, color: cs.primary),
                    const SizedBox(width: 5),
                    Text('Mark All Read',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          FilterChip(
            label: Text('Unread only',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _showUnreadOnly ? Colors.white : cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            selected: _showUnreadOnly,
            onSelected: (v) => setState(() => _showUnreadOnly = v),
            selectedColor: cs.primary,
            backgroundColor: cs.onSurface.withValues(alpha: 0.04),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 160, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 220, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 60, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Uicons.circleExclamation, size: 36, color: const Color(0xFFE53935).withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 6),
            Text(message,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<NotificationCubit>().loadNotifications(),
              icon: const Icon(Uicons.refresh, size: 16),
              label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, bool unreadOnly) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unreadOnly ? Uicons.checkCircle : Uicons.bellSlash,
                size: 38,
                color: cs.primary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              unreadOnly ? 'All caught up!' : 'No notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              unreadOnly ? 'You have no unread notifications' : 'You\'re all caught up!',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleNotification(NotificationModel notification, ColorScheme cs, bool isDark) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Uicons.trash, color: Color(0xFFE53935), size: 20),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x14E53935),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Uicons.trash, color: Color(0xFFE53935), size: 24),
                ),
                const SizedBox(height: 14),
                Text('Delete notification?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text('This notification will be permanently removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        context.read<NotificationCubit>().deleteNotification(notification.id);
      },
      child: _buildNotificationCard(notification, cs, isDark),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, ColorScheme cs, bool isDark) {
    final color = _typeColor(notification.type, cs);

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationCubit>().markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDark ? const Color(0xFF252525) : Colors.white)
              : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? cs.onSurface.withValues(alpha: 0.06)
                : color.withValues(alpha: 0.15),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(notification.type), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(notification.timeAgo,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
