import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_theme_cubit.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      image: 'assets/images/ecommerce-phone-happy-black-woman-with-credit-card-online-shopping-digital-payment-app-home-smile-banking-excited-african-girl-checks-cash-budget-money-growth-savings-online_590464-111903.jpg',
      title: 'Welcome to XerinMarket',
      description:
          'Shop from trusted sellers anywhere. Enjoy a seamless and secure online shopping experience.',
    ),
    _OnboardingItem(
      image: 'assets/images/35124.jpg',
      title: 'Sell Your Products Online',
      description:
          'Are you a seller? List your products on XerinMarket and reach customers across Tanzania. Start your business today at no high cost.',
    ),
    _OnboardingItem(
      image: 'assets/images/2150627997.jpg',
      title: 'For Brokers & Agents',
      description:
          'Connect sellers and buyers with ease. XerinMarket gives you a platform to grow your business and expand your broker network.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animCtrl.forward(from: 0);
  }

  Future<void> _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      await _markOnboardingSeen();
      if (mounted) context.go(AppConstants.signInRoute);
    }
  }

  Future<void> _onSkip() async {
    await _markOnboardingSeen();
    if (mounted) context.go(AppConstants.signInRoute);
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('has_seen_onboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final item = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Image covers top ~50% with smooth fade into scaffold background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.50,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) => Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index].image,
                    fit: BoxFit.cover,
                  ),
                  // Smooth gradient fade — transparent at top, scaffold bg at bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.0),
                          scaffoldBg.withValues(alpha: 0.3),
                          scaffoldBg.withValues(alpha: 0.8),
                          scaffoldBg.withValues(alpha: 1.0),
                        ],
                      ),
                    ),
                  ),
                  if (isDark)
                    Container(color: Colors.black.withValues(alpha: 0.12)),
                ],
              ),
            ),
          ),
          // Top bar — theme toggle + skip
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeToggleButton(),
                if (!isLast) _buildSkipButton(),
              ],
            ),
          ),
          // Bottom content — text + button on scaffold background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: _buildBottomContent(item, isLast, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton() {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      bloc: sl<AppThemeCubit>(),
      builder: (context, state) {
        final dark = state.isDark ||
            (state.isSystem &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => sl<AppThemeCubit>().toggleTheme(),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(dark),
                size: 22,
                color: Colors.white,
              ),
            ),
            tooltip: dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            splashRadius: 22,
          ),
        );
      },
    );
  }

  Widget _buildSkipButton() {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _onSkip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Skip',
          style: GoogleFonts.nunito(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent(_OnboardingItem item, bool isLast, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              item.title,
              style: GoogleFonts.nunito(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              item.description,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            // Single button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLast ? 'Get Started' : 'Next',
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String image;
  final String title;
  final String description;

  const _OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}
