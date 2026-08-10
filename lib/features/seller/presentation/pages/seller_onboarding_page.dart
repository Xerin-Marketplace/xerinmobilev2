import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';

class SellerOnboardingPage extends StatefulWidget {
  const SellerOnboardingPage({super.key});

  @override
  State<SellerOnboardingPage> createState() => _SellerOnboardingPageState();
}

class _SellerOnboardingPageState extends State<SellerOnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  final List<_SellerOnboardItem> _pages = const [
    _SellerOnboardItem(
      icon: Icons.store_rounded,
      title: 'Your Shop is Ready!',
      description:
          'You\'ve taken the first step toward building your business on XerinMarket. '
          'Customers across Tanzania are ready to discover your products.',
      color: Color(0xFFF47524),
      gradientColors: [Color(0xFFF47524), Color(0xFFFF8A50)],
    ),
    _SellerOnboardItem(
      icon: Icons.inventory_2_rounded,
      title: 'List Your Products',
      description:
          'Upload product photos, set prices, and manage inventory with '
          'our easy-to-use seller tools. Add unlimited products to your shop.',
      color: Color(0xFF3B82F6),
      gradientColors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    ),
    _SellerOnboardItem(
      icon: Icons.track_changes_rounded,
      title: 'Track & Fulfill Orders',
      description:
          'Get real-time order notifications, print shipping labels, and '
          'keep your customers updated every step of the way.',
      color: Color(0xFF22C55E),
      gradientColors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
    ),
    _SellerOnboardItem(
      icon: Icons.trending_up_rounded,
      title: 'Grow Your Business',
      description:
          'Access sales analytics, customer insights, and promotional tools '
          'to take your shop to the next level. Start earning today!',
      color: Color(0xFF8B5CF6),
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
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

  void _onFinish() {
    context.go(AppConstants.registrationSuccessRoute);
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
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 22,
                ),
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: _onFinish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSection(
      _SellerOnboardItem item, ColorScheme colorScheme, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.gradientColors[0],
                item.gradientColors[1].withValues(alpha: 0.85),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPatternPainter(color: item.color),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '${_currentPage + 1}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.1),
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme, bool isDark) {
    final isLast = _currentPage == _pages.length - 1;

    return ClipPath(
      clipper: _SellerCurveClipper(),
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
        padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      _pages[_currentPage].title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _pages[_currentPage].description,
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index, colorScheme),
              ),
            ),
            const SizedBox(height: 32),
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
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const _SellerAnimatedArrow(),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _onFinish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Finish',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.onPrimary,
                            size: 22,
                          ),
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

  Widget _buildDot(int index, ColorScheme colorScheme) {
    final isActive = index == _currentPage;
    final item = _pages[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 30 : 8,
      height: 8,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  item.gradientColors[0],
                  item.gradientColors[1],
                ],
              )
            : LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SellerOnboardItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradientColors;

  const _SellerOnboardItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradientColors,
  });
}

class _SellerCurveClipper extends CustomClipper<Path> {
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

class _SellerAnimatedArrow extends StatefulWidget {
  const _SellerAnimatedArrow();

  @override
  State<_SellerAnimatedArrow> createState() => _SellerAnimatedArrowState();
}

class _SellerAnimatedArrowState extends State<_SellerAnimatedArrow>
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
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;

  _BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      60,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      100,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8),
      40,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.8),
      70,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
