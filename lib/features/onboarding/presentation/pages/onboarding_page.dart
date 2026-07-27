import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  late final AnimationController _arrowCtrl;
  late final Animation<double> _arrowAnim;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      image: 'assets/onboarding/1stonbaoidng .jpg',
      icon: Icons.storefront_rounded,
      title: 'Welcome to Xerin',
      description:
          'Discover a marketplace built for everyone. Shop, sell, and connect with trusted vendors from one beautiful app.',
      gradientColors: [Color(0xFFF47524), Color(0xFFFF8A50)],
    ),
    _OnboardingItem(
      image: 'assets/onboarding/deliveryobaording.jpg',
      icon: Icons.local_shipping_rounded,
      title: 'Fast Delivery',
      description:
          'From cart to doorstep in record time. We deliver your orders quickly, safely, and reliably — every single time.',
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
    _OnboardingItem(
      image: 'assets/onboarding/deliveryobaording.jpg',
      icon: Icons.lock_rounded,
      title: 'Secure Payments',
      description:
          'Pay with confidence using encrypted, secure transactions. Your data and money are always protected with us.',
      gradientColors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _arrowAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _arrowCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _animCtrl.forward(from: 0);
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onSkip() async {
    await _markOnboardingSeen();
    if (mounted) context.go(AppConstants.signInRoute);
  }

  Future<void> _onGetStarted() async {
    await _markOnboardingSeen();
    if (mounted) context.go(AppConstants.signInRoute);
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool('has_seen_onboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 6,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _buildTopSection(_pages[index], colorScheme, isDark),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -50),
                child: _buildBottomSection(colorScheme, isDark),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: _buildThemeToggleButton(),
          ),
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildSkipButton(colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton() {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      bloc: sl<AppThemeCubit>(),
      builder: (context, state) {
        final isDark = state.isDark ||
            (state.isSystem &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return GestureDetector(
          onTap: () => sl<AppThemeCubit>().toggleTheme(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDark ? Colors.amber : Colors.orange,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSection(_OnboardingItem item, ColorScheme colorScheme, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          item.image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.05),
                Colors.transparent,
                isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _onSkip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.skip_next_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme, bool isDark) {
    final isLast = _currentPage == _pages.length - 1;
    final item = _pages[_currentPage];

    return ClipPath(
      clipper: _UpwardCurveClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(32, 56, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.gradientColors.first,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Step ${_currentPage + 1} of ${_pages.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.gradientColors.first,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.gradientColors.first,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index, colorScheme, item),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  GestureDetector(
                    onTap: _onBack,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 52),
                if (!isLast)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _arrowAnim,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -_arrowAnim.value - 12),
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: item.gradientColors.first.withValues(alpha: 0.5),
                          size: 24,
                        ),
                      ),
                      GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.gradientColors.first
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: AnimatedArrow(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _onGetStarted,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: item.gradientColors.first
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedArrow(color: Colors.white),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, ColorScheme colorScheme, _OnboardingItem item) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 30 : 8,
      height: 8,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(colors: item.gradientColors)
            : LinearGradient(
                colors: [
                  colorScheme.onSurface.withValues(alpha: 0.12),
                  colorScheme.onSurface.withValues(alpha: 0.12),
                ],
              ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingItem {
  final String image;
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const _OnboardingItem({
    required this.image,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

class _UpwardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, 40)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, 40)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AnimatedArrow extends StatefulWidget {
  final Color color;
  const AnimatedArrow({super.key, required this.color});

  @override
  State<AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<AnimatedArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: Icon(
        Icons.arrow_forward_rounded,
        color: widget.color,
        size: 24,
      ),
    );
  }
}
