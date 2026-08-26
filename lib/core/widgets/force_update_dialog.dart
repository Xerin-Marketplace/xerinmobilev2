import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version_service.dart';

/// A non-dismissible dialog that forces the user to update the app.
///
/// Shown when [VersionCheckResult.needsUpdate] is `true`. The user
/// cannot dismiss the dialog — the only action is "Update Now" which
/// opens the Play Store / App Store listing.
class ForceUpdateDialog extends StatelessWidget {
  final VersionCheckResult result;

  const ForceUpdateDialog({super.key, required this.result});

  /// Shows the dialog as a route that cannot be popped.
  static Future<void> show(BuildContext context, VersionCheckResult result) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        barrierDismissible: false,
        opaque: false,
        pageBuilder: (context, _, __) => ForceUpdateDialog(result: result),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final url = result.downloadUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update URL not available. Please update from the Play Store.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open store. URL: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = result.maintenanceMode || !result.appEnabled;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: (isMaintenance ? Colors.orange : Colors.red).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMaintenance ? Icons.build_circle_outlined : Icons.system_update_alt,
                  size: 36,
                  color: isMaintenance ? Colors.orange : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isMaintenance ? 'Under Maintenance' : 'Update Required',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isMaintenance
                    ? (result.maintenanceMessage ??
                        'XerinMarket is currently under maintenance. Please check back soon.')
                    : 'A new version of XerinMarket is available. '
                      'Please update to the latest version to continue using the app.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (!isMaintenance && result.minVersion != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Minimum version: ${result.minVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!isMaintenance)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openStore(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Update Now'),
                  ),
                ),
              if (!isMaintenance)
                const SizedBox(height: 12),
              if (!isMaintenance)
                TextButton(
                  onPressed: () {
                    // Re-check — allows user to retry after updating.
                  },
                  child: const Text('I\'ve updated — recheck'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
