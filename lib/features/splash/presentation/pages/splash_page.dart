import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/services/app_version_service.dart';
import '../../../../core/services/in_app_update_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/force_update_dialog.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoCtrl.forward();

    _navigateAfterSplash();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 1. Check Google Play for in-app update (native, Android only)
    try {
      final updateService = GetIt.instance<InAppUpdateService>();
      final updateResult = await updateService.checkForUpdate();

      if (mounted && updateResult.status == InAppUpdateStatus.immediateRequired) {
        // Full-screen forced update — blocks until installed
        await updateService.startImmediateUpdate();
        // After immediate update completes, re-check
        if (!mounted) return;
        final recheck = await updateService.checkForUpdate();
        if (recheck.status == InAppUpdateStatus.immediateRequired) {
          // Still needs update — fall through to backend force dialog
          final versionService = GetIt.instance<AppVersionService>();
          final result = await versionService.checkVersion();
          if (mounted && (result.needsUpdate || result.maintenanceMode || !result.appEnabled)) {
            ForceUpdateDialog.show(context, result);
            return;
          }
        }
      } else if (mounted && updateResult.status == InAppUpdateStatus.updateAvailable) {
        // Flexible update — show dialog, user can accept or defer
        final shouldUpdate = await _showFlexibleUpdateDialog(updateResult);
        if (shouldUpdate == true) {
          await updateService.startFlexibleUpdate();
        }
        if (!mounted) return;
      }
    } catch (_) {
      // In-app update failed silently — fall through to backend check
    }

    if (!mounted) return;

    // 2. Backend version check (fallback for non-Play or when in-app not available)
    try {
      final versionService = GetIt.instance<AppVersionService>();
      final result = await versionService.checkVersion();
      if (mounted && (result.needsUpdate || result.maintenanceMode || !result.appEnabled)) {
        ForceUpdateDialog.show(context, result);
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    final tokenStorage = GetIt.instance<TokenStorage>();
    final prefs = GetIt.instance<SharedPreferences>();
    final securityService = GetIt.instance<SecurityService>();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!tokenStorage.hasTokens) {
      if (hasSeenOnboarding) {
        context.go(AppConstants.signInRoute);
      } else {
        context.go(AppConstants.onboardingRoute);
      }
      return;
    }

    bool sessionValid = false;
    try {
      final dataSource = GetIt.instance<AuthRemoteDataSource>();
      await dataSource.getMyProfile();
      sessionValid = true;
    } catch (_) {
      sessionValid = false;
    }

    if (!mounted) return;

    if (sessionValid && securityService.isPinLockEnabled) {
      context.go(AppConstants.lockRoute);
    } else if (sessionValid) {
      final user = tokenStorage.currentUser;
      context.go(AppConstants.dashboardRouteForUser(user));
    } else {
      await tokenStorage.clearTokens();
      if (!mounted) return;
      context.go(AppConstants.signInRoute);
    }
  }

  Future<bool?> _showFlexibleUpdateDialog(InAppUpdateResult result) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Image.asset(
                    'assets/logo/mark.png',
                    width: 220,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _logoFade,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFFF47524).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
