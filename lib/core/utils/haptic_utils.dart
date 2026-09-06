import 'package:flutter/services.dart';

/// Lightweight haptic feedback helpers for tactile UX.
abstract class HapticUtils {
  /// Light impact — for button presses, tab switches, toggles.
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact — for card taps, list item selections.
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy impact — for significant state changes, drag releases.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Selection click — for picker/selector changes.
  static void selection() => HapticFeedback.selectionClick();

  /// Success vibration pattern — for completed actions (order placed, etc).
  static void success() => HapticFeedback.mediumImpact();

  /// Warning vibration pattern — for error states.
  static void warning() => HapticFeedback.heavyImpact();

  /// Error vibration pattern — for failures.
  static void error() => HapticFeedback.vibrate();
}
