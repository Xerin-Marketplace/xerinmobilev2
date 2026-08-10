import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../notifications/notification_service.dart';

/// Global logger instance for the app.
final Logger logger = Logger();

/// Helper for showing smooth top notifications.
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  final notification = NotificationService();
  if (isError) {
    notification.error(message);
  } else {
    notification.success(message);
  }
}

/// Helper for dismissing keyboard.
void dismissKeyboard(BuildContext context) {
  FocusScope.of(context).unfocus();
}

/// Helper for formatting numbers as two digits.
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Formats an order UUID + optional date into a commercial order reference.
/// Format: XM-YYMMDD-NNNNN (e.g. XM-260811-00125)
/// Uses the date for the YYMMDD portion, and derives a 5-digit sequence from the UUID hash.
String formatOrderRef(String uuid, [String? createdAt]) {
  // Try to parse date from createdAt or use current date
  DateTime date;
  try {
    date = createdAt != null && createdAt.isNotEmpty
        ? DateTime.parse(createdAt)
        : DateTime.now();
  } catch (_) {
    date = DateTime.now();
  }

  final yy = (date.year % 100).toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');

  // Derive a 5-digit sequence number from the UUID hash
  int hash = 0;
  for (int i = 0; i < uuid.length; i++) {
    hash = ((hash << 5) - hash) + uuid.codeUnitAt(i);
    hash = hash & 0x7FFFFFFF; // Keep it positive
  }
  final seq = (hash % 100000).toString().padLeft(5, '0');

  return 'XM-$yy$mm$dd-$seq';
}
