import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _notifications.addAll(_sampleNotifications);
          _isLoading = false;
        });
      }
    });
  }

  void _markAllRead() {
    setState(() {
      for (final _ in _notifications) {}
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All marked as read'), backgroundColor: Color(0xFF22C55E)),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order': return Icons.shopping_bag_rounded;
      case 'promo': return Icons.local_offer_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'system': return Icons.info_outline_rounded;
      default: return Icons.notifications_outlined;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  BackIconButton(
                    onTap: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('Notifications',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                  if (_notifications.any((n) => !n.isRead))
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Mark All Read',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_notifications.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text('You\'re all caught up!',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification, colorScheme);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, ColorScheme colorScheme) {
    final color = _typeColor(notification.type, colorScheme);

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          setState(() {
            final idx = _notifications.indexOf(notification);
            if (idx >= 0) {
              _notifications[idx] = NotificationModel(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                isRead: true,
                createdAt: notification.createdAt,
              );
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? colorScheme.surface
              : colorScheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? colorScheme.onSurface.withValues(alpha: 0.04)
                : color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(notification.type), color: color, size: 20),
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
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.message,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(notification.timeAgo,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<NotificationModel> _sampleNotifications = [
    NotificationModel(id: 'n1', title: 'Order Delivered!', message: 'Your Premium Leather Bag has been delivered successfully.', type: 'order', isRead: false, createdAt: '2024-12-25T10:30:00'),
    NotificationModel(id: 'n2', title: 'Flash Sale Alert', message: '50% off on electronics! Hurry, offer ends tonight.', type: 'promo', isRead: false, createdAt: '2024-12-24T14:00:00'),
    NotificationModel(id: 'n3', title: 'Payment Confirmed', message: 'Your payment of TZS 45,000 for order #XERIN-001 has been received.', type: 'payment', isRead: true, createdAt: '2024-12-23T09:15:00'),
    NotificationModel(id: 'n4', title: 'Order Shipped', message: 'Your Smart Watch Pro is on its way! Track your delivery now.', type: 'order', isRead: true, createdAt: '2024-12-22T16:45:00'),
    NotificationModel(id: 'n5', title: 'Welcome to XerinMarket!', message: 'Thank you for joining. Enjoy shopping with the best deals in Tanzania.', type: 'system', isRead: true, createdAt: '2024-12-20T08:00:00'),
    NotificationModel(id: 'n6', title: 'New Feature Available', message: 'You can now track your orders in real-time. Check it out!', type: 'system', isRead: false, createdAt: '2024-12-26T11:00:00'),
  ];
}
