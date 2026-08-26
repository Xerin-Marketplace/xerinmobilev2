import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/constants/api_constants.dart';
import '../../config/constants/app_constants.dart';
import '../network/api_client.dart';

/// Result of a version check against the backend settings.
class VersionCheckResult {
  final bool needsUpdate;
  final bool forceUpdate;
  final String? minVersion;
  final String? downloadUrl;
  final String? maintenanceMessage;
  final bool maintenanceMode;
  final bool appEnabled;

  const VersionCheckResult({
    required this.needsUpdate,
    required this.forceUpdate,
    this.minVersion,
    this.downloadUrl,
    this.maintenanceMessage,
    this.maintenanceMode = false,
    this.appEnabled = true,
  });

  static const VersionCheckResult ok = VersionCheckResult(
    needsUpdate: false,
    forceUpdate: false,
  );
}

/// Service that checks the app version against backend system settings.
///
/// On app launch it fetches the public mobile-app settings from the
/// backend (`/settings?category=mobile&public_only=true`) and compares
/// the current app version with `mobile_app_min_version`.  If the
/// installed version is lower, or `mobile_app_force_update` is `true`,
/// the caller should present a non-dismissible update dialog.
class AppVersionService {
  final ApiClient _client;
  final Logger _logger;

  AppVersionService(this._client, this._logger);

  /// Fetches public mobile-app settings from the backend and returns a
  /// [VersionCheckResult].  Network failures are treated as "ok" so
  /// users are never blocked by a transient API error.
  Future<VersionCheckResult> checkVersion() async {
    try {
      final response = await _client.get(
        ApiConstants.systemSettings,
        queryParameters: {
          'category': 'mobile',
          'public_only': true,
          'page_size': 50,
        },
      );

      final data = response.data;
      List<dynamic> results;
      if (data is Map<String, dynamic>) {
        results = data['results'] as List<dynamic>? ?? [];
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      final settings = <String, String>{};
      for (final item in results) {
        if (item is Map<String, dynamic>) {
          final key = item['key']?.toString();
          final value = item['value']?.toString();
          if (key != null && value != null) {
            settings[key] = value;
          }
        }
      }

      // Also check platform-level maintenance mode.
      final platformMaintenance = settings['maintenance_mode']?.toLowerCase() == 'true';
      final appEnabled = settings['mobile_app_enabled']?.toLowerCase() != 'false';
      final forceUpdate = settings['mobile_app_force_update']?.toLowerCase() == 'true';
      final minVersion = settings['mobile_app_min_version'];
      final maintenanceMessage = settings['mobile_app_maintenance_message'];

      // Determine download URL based on platform.
      String? downloadUrl;
      if (defaultTargetPlatform == TargetPlatform.android) {
        downloadUrl = settings['mobile_app_download_url_android'];
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        downloadUrl = settings['mobile_app_download_url_ios'];
      }

      // Get current installed version.
      String currentVersion = AppConstants.appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        currentVersion = info.version;
      } catch (_) {}

      final needsUpdate = _isVersionBelow(currentVersion, minVersion);

      _logger.i('AppVersionService: current=$currentVersion, min=$minVersion, '
          'force=$forceUpdate, needsUpdate=$needsUpdate, '
          'maintenance=$platformMaintenance, appEnabled=$appEnabled');

      return VersionCheckResult(
        needsUpdate: needsUpdate || forceUpdate,
        forceUpdate: needsUpdate || forceUpdate,
        minVersion: minVersion,
        downloadUrl: downloadUrl,
        maintenanceMessage: maintenanceMessage,
        maintenanceMode: platformMaintenance,
        appEnabled: appEnabled,
      );
    } on DioException catch (e) {
      _logger.w('AppVersionService: network error during version check: $e');
      return VersionCheckResult.ok;
    } catch (e) {
      _logger.w('AppVersionService: unexpected error during version check: $e');
      return VersionCheckResult.ok;
    }
  }

  /// Returns `true` if [current] is strictly below [minimum].
  ///
  /// Versions are compared semantically (e.g. "1.0.3" < "1.0.7" < "1.2.0").
  /// If [minimum] is null or empty, `false` is returned (no constraint).
  bool _isVersionBelow(String current, String? minimum) {
    if (minimum == null || minimum.trim().isEmpty) return false;

    final curParts = _parseVersion(current);
    final minParts = _parseVersion(minimum);

    final maxLen =
        curParts.length > minParts.length ? curParts.length : minParts.length;

    for (var i = 0; i < maxLen; i++) {
      final cur = i < curParts.length ? curParts[i] : 0;
      final min = i < minParts.length ? minParts[i] : 0;

      if (cur < min) return true;
      if (cur > min) return false;
    }

    return false; // versions are equal
  }

  List<int> _parseVersion(String version) {
    // Strip any pre-release suffix (e.g. "1.0.0-beta.1" → "1.0.0").
    final clean = version.split(RegExp(r'[-+]')).first;
    return clean
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
