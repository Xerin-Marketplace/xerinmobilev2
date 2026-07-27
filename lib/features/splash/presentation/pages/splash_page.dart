import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/storage/token_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final tokenStorage = GetIt.instance<TokenStorage>();
    final prefs = GetIt.instance<SharedPreferences>();
    final isLoggedIn = tokenStorage.hasTokens;
    final isGuest = tokenStorage.isGuestMode;
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (isLoggedIn || isGuest) {
      context.go(AppConstants.homeRoute);
    } else if (hasSeenOnboarding) {
      context.go(AppConstants.signInRoute);
    } else {
      context.go(AppConstants.onboardingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'assets/logo/logo.png',
                width: 280,
                height: 200,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFF47524).withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'XerinMarket',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
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
