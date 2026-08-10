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
