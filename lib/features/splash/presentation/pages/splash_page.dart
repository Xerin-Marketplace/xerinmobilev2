import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/services/app_version_service.dart';
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
      context.go(AppConstants.signInRoute);
    }
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
