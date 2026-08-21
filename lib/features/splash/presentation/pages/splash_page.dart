import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/storage/token_storage.dart';

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
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoCtrl.forward();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _navigateAfterSplash();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final tokenStorage = GetIt.instance<TokenStorage>();
    final prefs = GetIt.instance<SharedPreferences>();
    final securityService = GetIt.instance<SecurityService>();
    final isLoggedIn = tokenStorage.hasTokens;
    final isGuest = tokenStorage.isGuestMode;
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if ((isLoggedIn || isGuest) && securityService.isPinLockEnabled) {
      context.go(AppConstants.lockRoute);
    } else if (isLoggedIn) {
      context.go(AppConstants.homeRoute);
    } else if (isGuest) {
      context.go(AppConstants.homeRoute);
    } else if (hasSeenOnboarding) {
      context.go(AppConstants.signInRoute);
    } else {
      context.go(AppConstants.onboardingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [const Color(0xFFFFFFFF), const Color(0xFFFFF5EE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF47524).withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo/logo.png',
                          width: 280,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _shimmerAnim,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment(_shimmerAnim.value - 0.5, 0),
                        end: Alignment(_shimmerAnim.value + 0.5, 0),
                        colors: [
                          const Color(0xFFF47524).withValues(alpha: 0.3),
                          const Color(0xFFF47524).withValues(alpha: 0.8),
                          const Color(0xFFF47524).withValues(alpha: 0.3),
                        ],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _logoFade,
                child: Text(
                  'XerinMarket v${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF47524).withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
