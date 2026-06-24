import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bgDark;
  final Color bgCard;
  final Color bgSurface;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderLight;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppColorsExtension({
    required this.bgDark,
    required this.bgCard,
    required this.bgSurface,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? bgDark, Color? bgCard, Color? bgSurface, Color? bgElevated,
    Color? textPrimary, Color? textSecondary, Color? textMuted,
    Color? border, Color? borderLight,
    Color? success, Color? warning, Color? error, Color? info,
  }) {
    return AppColorsExtension(
      bgDark: bgDark ?? this.bgDark,
      bgCard: bgCard ?? this.bgCard,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bgDark: Color.lerp(bgDark, other.bgDark, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;

  LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppTheme.primary, Color(0xFF3B82F6)],
  );

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colors.bgCard, colors.bgSurface],
  );

  LinearGradient get liveGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );
}

class AppTheme {
  // ─── Brand Colors ───
  static const Color primary = Color(0xFF0052FF);
  static const Color primaryLight = Color(0xFF4D88FF);
  static const Color primaryDark = Color(0xFF003BB3);

  static const Color secondary = Color(0xFF0F172A);
  static const Color secondaryLight = Color(0xFF1E293B);
  static const Color secondaryDark = Color(0xFF020617);

  static const Color accent = Color(0xFF22C55E);
  static const Color accentDark = Color(0xFF15803D);

  // ─── Role Colors ───
  static const Color adminColor = Color(0xFFEF4444);
  static const Color refereeColor = Color(0xFFF59E0B);
  static const Color viewerColor = Color(0xFF3B82F6);

  // ─── Constants ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ─── Extensions ───
  static const AppColorsExtension _darkColors = AppColorsExtension(
    bgDark: Color(0xFF0B0F19),
    bgCard: Color(0xFF151C2C),
    bgSurface: Color(0xFF1F293D),
    bgElevated: Color(0xFF2E3B55),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF475569),
    border: Color(0xFF1F293D),
    borderLight: Color(0xFF151C2C),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );

  static const AppColorsExtension _lightColors = AppColorsExtension(
    bgDark: Color(0xFFF8FAFC),
    bgCard: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFF1F5F9),
    bgElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    borderLight: Color(0xFFF1F5F9),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );

  static ThemeData _buildTheme(Brightness brightness, AppColorsExtension colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bgDark,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: colors.error,
        onError: Colors.white,
        surface: colors.bgCard,
        onSurface: colors.textPrimary,
      ),
      extensions: [colors],
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary, letterSpacing: -0.5),
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: colors.textPrimary),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.textPrimary),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colors.textMuted),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, letterSpacing: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: colors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusMedium), borderSide: BorderSide(color: colors.error)),
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textMuted),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: Colors.white, elevation: 4),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.bgElevated,
        contentTextStyle: GoogleFonts.inter(color: colors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.bgCard,
        selectedItemColor: primary,
        unselectedItemColor: colors.textMuted,
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme(Brightness.dark, _darkColors);
  static ThemeData get lightTheme => _buildTheme(Brightness.light, _lightColors);
}
