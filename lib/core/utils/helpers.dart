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
