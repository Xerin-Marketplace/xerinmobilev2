import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

/// Result of an in-app update check.
enum InAppUpdateStatus {
  /// No update is available.
  noUpdate,
  /// An update is available and can be downloaded flexibly.
  updateAvailable,
  /// An immediate (forced) update is required.
  immediateRequired,
  /// The update flow is already in progress.
  inProgress,
  /// In-app updates are not supported on this platform/device.
  notSupported,
  /// An error occurred during the check.
  error,
}

/// Result object carrying status and optional metadata.
class InAppUpdateResult {
  final InAppUpdateStatus status;
  final String? message;
  final int? availableVersionCode;

  const InAppUpdateResult({
    required this.status,
    this.message,
    this.availableVersionCode,
  });
}

/// Service that integrates with the Google Play In-App Updates API.
///
/// On Android, this uses the Play Core library to check for updates and
/// present either a flexible update dialog (user can continue using the
/// app while it downloads) or an immediate update (full-screen, forced).
///
/// On non-Android platforms, [checkForUpdate] returns [InAppUpdateStatus.notSupported].
class InAppUpdateService {
  final Logger _logger;

  InAppUpdateService(this._logger);

  /// Checks whether an in-app update is available from the Play Store.
  ///
  /// Returns [InAppUpdateResult] describing the availability. On non-Android
  /// platforms, returns [InAppUpdateStatus.notSupported].
  Future<InAppUpdateResult> checkForUpdate() async {
    if (!defaultTargetPlatform.isAndroid) {
      return const InAppUpdateResult(
        status: InAppUpdateStatus.notSupported,
        message: 'In-app updates are only available on Android.',
      );
    }

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      _logger.i('InAppUpdateService: updateAvailability=${info.updateAvailability}, '
          'immediateAllowed=${info.immediateUpdateAllowed}, '
          'flexibleAllowed=${info.flexibleUpdateAllowed}, '
          'availableVersionCode=${info.availableVersionCode}');

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          return InAppUpdateResult(
            status: InAppUpdateStatus.immediateRequired,
            availableVersionCode: info.availableVersionCode,
          );
        } else if (info.flexibleUpdateAllowed) {
          return InAppUpdateResult(
            status: InAppUpdateStatus.updateAvailable,
            availableVersionCode: info.availableVersionCode,
          );
        }
        return const InAppUpdateResult(
          status: InAppUpdateStatus.updateAvailable,
          message: 'Update available but not allowed to start in-app.',
        );
      }

      return const InAppUpdateResult(status: InAppUpdateStatus.noUpdate);
    } catch (e) {
      _logger.w('InAppUpdateService: error checking for update: $e');
      return InAppUpdateResult(
        status: InAppUpdateStatus.error,
        message: e.toString(),
      );
    }
  }

  /// Starts a **flexible** in-app update flow.
  ///
  /// The user can continue using the app while the update downloads in the
  /// background. When complete, a snackbar prompts the user to restart.
  ///
  /// Returns `true` if the update flow completed successfully.
  Future<bool> startFlexibleUpdate({
    GlobalKey<NavigatorState>? navigatorKey,
    VoidCallback? onComplete,
  }) async {
    if (!defaultTargetPlatform.isAndroid) return false;

    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      _logger.i('InAppUpdateService: flexible update result=$result');

      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate();
        _logger.i('InAppUpdateService: flexible update completed and installed');
        onComplete?.call();
        return true;
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        _logger.w('InAppUpdateService: user denied flexible update');
        return false;
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        _logger.w('InAppUpdateService: flexible update failed');
        return false;
      }
      return false;
    } catch (e) {
      _logger.w('InAppUpdateService: error during flexible update: $e');
      return false;
    }
  }

  /// Starts an **immediate** (forced) in-app update flow.
  ///
  /// This takes over the full screen and blocks user interaction until
  /// the update is downloaded and installed. The user cannot dismiss it.
  ///
  /// Returns `true` if the update flow completed successfully.
  Future<bool> startImmediateUpdate() async {
    if (!defaultTargetPlatform.isAndroid) return false;

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _logger.i('InAppUpdateService: immediate update result=$result');

      if (result == AppUpdateResult.success) {
        _logger.i('InAppUpdateService: immediate update completed');
        return true;
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        _logger.w('InAppUpdateService: user denied immediate update');
        return false;
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        _logger.w('InAppUpdateService: immediate update failed');
        return false;
      }
      return false;
    } catch (e) {
      _logger.w('InAppUpdateService: error during immediate update: $e');
      return false;
    }
  }

  /// Convenience method: checks for update and automatically starts the
  /// appropriate flow.
  ///
  /// - If [immediateRequired], starts immediate update (full-screen, forced).
  /// - If [updateAvailable], shows a dialog asking the user to update. If
  ///   they accept, starts a flexible update.
  /// - Otherwise, does nothing.
  ///
  /// Returns `true` if an update was started or completed.
  Future<bool> checkAndPerformUpdate(BuildContext context) async {
    final result = await checkForUpdate();

    switch (result.status) {
      case InAppUpdateStatus.immediateRequired:
        return startImmediateUpdate();

      case InAppUpdateStatus.updateAvailable:
        if (!context.mounted) return false;
        final shouldUpdate = await _showUpdateDialog(context, result);
        if (shouldUpdate == true) {
          return startFlexibleUpdate();
        }
        return false;

      case InAppUpdateStatus.noUpdate:
      case InAppUpdateStatus.notSupported:
      case InAppUpdateStatus.inProgress:
      case InAppUpdateStatus.error:
        return false;
    }
  }

  /// Shows a dialog asking the user to start a flexible update.
  Future<bool?> _showUpdateDialog(
    BuildContext context,
    InAppUpdateResult result,
  ) {
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Update Available')),
        ]),
        content: Text(
          'A new version of XerinMarket is available on the Play Store. '
          '${result.availableVersionCode != null ? '(Build #${result.availableVersionCode})\n' : ''}'
          'Would you like to update now? You can continue using the app while it downloads.',
          style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

/// Extension to check if the platform is Android.
extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
