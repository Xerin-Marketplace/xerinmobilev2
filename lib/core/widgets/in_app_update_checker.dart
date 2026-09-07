import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/in_app_update_service.dart';

/// A widget that checks for in-app updates when the app resumes.
///
/// Wrap your main app content with this widget to automatically check
/// for Play Store updates when the app is brought back to the foreground.
/// If a flexible update is available, it shows a snackbar with an action
/// to start the update. If an immediate update is required, it starts
/// the full-screen update flow automatically.
class InAppUpdateChecker extends StatefulWidget {
  final Widget child;

  const InAppUpdateChecker({super.key, required this.child});

  @override
  State<InAppUpdateChecker> createState() => _InAppUpdateCheckerState();
}

class _InAppUpdateCheckerState extends State<InAppUpdateChecker>
    with WidgetsBindingObserver {
  bool _checkedOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checkedOnResume) {
      _checkedOnResume = true;
      _checkForUpdate();
    } else if (state == AppLifecycleState.paused) {
      _checkedOnResume = false;
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final service = GetIt.instance<InAppUpdateService>();
      final result = await service.checkForUpdate();

      if (!mounted) return;

      switch (result.status) {
        case InAppUpdateStatus.immediateRequired:
          await service.startImmediateUpdate();
          break;

        case InAppUpdateStatus.updateAvailable:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A new version is available'),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Update',
                onPressed: () {
                  service.startFlexibleUpdate();
                },
              ),
            ),
          );
          break;

        case InAppUpdateStatus.noUpdate:
        case InAppUpdateStatus.notSupported:
        case InAppUpdateStatus.inProgress:
        case InAppUpdateStatus.error:
          break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
