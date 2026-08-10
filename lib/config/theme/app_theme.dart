import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFFF47524);
  static const Color secondary = Color(0xFF434951);
  static const Color error = Color(0xFFE53935);

  // Extended brand colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFFF9D57);
  static const Color primaryDark = Color(0xFFD45A1A);

  // Light theme palette
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightCard = Colors.white;
  static const Color _lightInput = Color(0xFFF1F3F5);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textLight = Color(0xFF6B7280);

  // Dark theme palette
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF252525);
  static const Color _darkInput = Color(0xFF2A2A2A);
  static const Color _textOnDark = Color(0xFFF5F5F5);
  static const Color _textOnDarkMuted = Color(0xFFB0B0B0);

  // Brand gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: isDark ? _darkSurface : _lightSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
      textTheme: GoogleFonts.nunitoTextTheme(baseTextTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? _darkSurface : _lightSurface,
        foregroundColor: isDark ? _textOnDark : _textDark,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? _textOnDark : _textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? _darkCard : _lightCard,
        elevation: 2,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? _darkInput : const Color(0xFFDCDEE0),
          disabledForegroundColor: isDark ? _textOnDarkMuted : _textLight,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.35),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.18);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.1);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: isDark ? _textOnDarkMuted : _textLight,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return primary.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _darkInput : _lightInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: GoogleFonts.nunito(
          color: isDark ? _textOnDarkMuted : _textLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.nunito(
          color: isDark ? _textOnDarkMuted : _textLight,
        ),
        errorStyle: GoogleFonts.nunito(
          color: error,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? _darkSurface : _lightSurface,
        selectedItemColor: primary,
        unselectedItemColor: isDark ? _textOnDarkMuted : _textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.grey.shade200,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _darkCard : const Color(0xFF1A1A1A),
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _darkInput : _lightInput,
        selectedColor: primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? _textOnDark : _textDark,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? _darkSurface : _lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? _textOnDark : _textDark,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: isDark ? _textOnDarkMuted : _textLight,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: isDark ? _textOnDarkMuted : _textLight,
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? Colors.grey.shade700 : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.4);
          }
          return isDark ? Colors.white10 : Colors.grey.shade200;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return isDark ? Colors.white10 : Colors.grey.shade300;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.2),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: const Color(0xFFE53935),
        textColor: Colors.white,
        textStyle: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        smallSize: 16,
        largeSize: 20,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? _darkCard : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        preferBelow: true,
      ),
    );
  }
}
