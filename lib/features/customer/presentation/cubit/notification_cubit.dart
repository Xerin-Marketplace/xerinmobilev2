import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/notification_model.dart';
import '../../../admin/data/models/admin_dashboard_model.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    this.unreadCount = 0,
  });
}

class NotificationPrefsLoaded extends NotificationState {
  final NotificationPreferenceModel preferences;
  const NotificationPrefsLoaded(this.preferences);
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
}

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRemoteDataSource _dataSource;
  final Logger _logger;

  NotificationCubit({
    required NotificationRemoteDataSource dataSource,
    required Logger logger,
  })  : _dataSource = dataSource,
        _logger = logger,
        super(const NotificationInitial());

  Future<void> loadNotifications({int page = 1}) async {
    emit(const NotificationLoading());
    try {
      final notifications = await _dataSource.getNotifications(page: page);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(notifications: notifications, unreadCount: unreadCount));
    } catch (e) {
      _logger.e('❌ Failed to load notifications: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
      _logger.i('✅ Notification marked as read');
      await loadNotifications();
    } catch (e) {
      _logger.e('❌ Failed to mark notification: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      _logger.i('✅ All notifications marked as read');
      await loadNotifications();
    } catch (e) {
      _logger.e('❌ Failed to mark all: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dataSource.deleteNotification(notificationId);
      _logger.i('✅ Notification deleted');
      await loadNotifications();
    } catch (e) {
      _logger.e('❌ Failed to delete notification: $e');
    }
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await _dataSource.getPreferences();
      emit(NotificationPrefsLoaded(prefs));
    } catch (e) {
      _logger.e('❌ Failed to load preferences: $e');
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> updatePreferences(NotificationPreferenceModel prefs) async {
    try {
      final updated = await _dataSource.updatePreferences(prefs);
      emit(NotificationPrefsLoaded(updated));
      _logger.i('✅ Notification preferences updated');
    } catch (e) {
      _logger.e('❌ Failed to update preferences: $e');
      emit(NotificationError(e.toString()));
    }
  }
}
