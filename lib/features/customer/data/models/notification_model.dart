class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String event;
  final bool isRead;
  final String? actionUrl;
  final String? createdAt;
  final String? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'general',
    this.event = '',
    this.isRead = false,
    this.actionUrl,
    this.createdAt,
    this.readAt,
  });

  String get timeAgo {
    if (createdAt == null) return '';
    final now = DateTime.now();
    try {
      final date = DateTime.parse(createdAt!);
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return createdAt ?? '';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        event: json['event'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        actionUrl: json['action_url'] as String?,
        createdAt: json['created_at'] as String? ?? json['timestamp'] as String?,
        readAt: json['read_at'] as String?,
      );
}

class NotificationPreferenceModel {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderUpdates;
  final bool promotionAlerts;
  final bool securityAlerts;

  const NotificationPreferenceModel({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.orderUpdates = true,
    this.promotionAlerts = true,
    this.securityAlerts = true,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      orderUpdates: json['order_updates'] as bool? ?? true,
      promotionAlerts: json['promotion_alerts'] as bool? ?? true,
      securityAlerts: json['security_alerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
        'sms_enabled': smsEnabled,
        'order_updates': orderUpdates,
        'promotion_alerts': promotionAlerts,
        'security_alerts': securityAlerts,
      };

  NotificationPreferenceModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderUpdates,
    bool? promotionAlerts,
    bool? securityAlerts,
  }) {
    return NotificationPreferenceModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionAlerts: promotionAlerts ?? this.promotionAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
    );
  }
}

class NotificationSummary {
  final int total;
  final int unread;
  final int read;

  const NotificationSummary({this.total = 0, this.unread = 0, this.read = 0});

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      read: (json['read'] as num?)?.toInt() ?? 0,
    );
  }
}
