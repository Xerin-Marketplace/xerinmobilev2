import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme/app_theme.dart';

class NoInternetPage extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetPage({super.key, this.onRetry});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() => _isRetrying = false);
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtleColor =
        isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedIcon(isDark),
                  const SizedBox(height: 40),
                  _buildTitle(textColor),
                  const SizedBox(height: 12),
                  _buildSubtitle(subtleColor),
                  const SizedBox(height: 32),
                  _buildTipsCard(cardColor, textColor, subtleColor, isDark),
                  const SizedBox(height: 36),
                  _buildRetryButton(),
                  const SizedBox(height: 16),
                  _buildOfflineModeText(subtleColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse rings
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: ((1 - _pulseAnimation.value) * 0.4).clamp(0.0, 1.0),
              child: Container(
                width: 160 * _pulseAnimation.value,
                height: 160 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: ((1 - _pulseAnimation.value) * 0.25).clamp(0.0, 1.0),
              child: Container(
                width: 200 * _pulseAnimation.value,
                height: 200 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        // Main icon container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.15),
                AppTheme.primaryDark.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
              Positioned(
                bottom: 28,
                right: 28,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 20,
                    color: subtleColor(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color subtleColor(bool isDark) =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF6B7280);

  Widget _buildTitle(Color textColor) {
    return Text(
      'No Internet Connection',
      style: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(Color subtleColor) {
    return Text(
      'Oops! It looks like you\'re not connected\nto the internet. Check your connection\nand try again.',
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: subtleColor,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTipsCard(
    Color cardColor,
    Color textColor,
    Color subtleColor,
    bool isDark,
  ) {
    final tips = [
      _TipItem(
        icon: Icons.wifi_rounded,
        title: 'Check Wi-Fi',
        subtitle: 'Make sure Wi-Fi is turned on',
      ),
      _TipItem(
        icon: Icons.signal_cellular_alt_rounded,
        title: 'Check Mobile Data',
        subtitle: 'Ensure cellular data is active',
      ),
      _TipItem(
        icon: Icons.router_rounded,
        title: 'Restart Router',
        subtitle: 'Try restarting your router',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tips
            .map((tip) => _buildTipRow(tip, textColor, subtleColor))
            .toList(),
      ),
    );
  }

  Widget _buildTipRow(_TipItem tip, Color textColor, Color subtleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tip.icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip.subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtleColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: subtleColor,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isRetrying ? null : _handleRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          shadowColor: AppTheme.primary.withValues(alpha: 0.35),
        ),
        icon: _isRetrying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 24),
        label: Text(
          _isRetrying ? 'Retrying...' : 'Try Again',
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineModeText(Color subtleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: subtleColor),
        const SizedBox(width: 6),
        Text(
          'Some features may be unavailable offline',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtleColor,
          ),
        ),
      ],
    );
  }
}

class _TipItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
