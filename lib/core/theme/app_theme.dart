import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Semantic color palette for Nearby
class AppColorPalette {
  final Color bg;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceHigh;
  final Color line;
  final Color lineSubtle;

  final Color ink;
  final Color muted;
  final Color inverseInk;

  final Color primary;
  final Color primaryDark;
  final Color primarySoft;

  final Color accent;
  final Color accentDark;
  final Color accentSoft;

  final Color sos;
  final Color sosDark;
  final Color sosSoft;
  final Color sosGlow;

  final Color info;
  final Color infoSoft;

  final Color violet;
  final Color violetSoft;

  final Color btnBg;
  final Color btnInk;

  final bool isEmergency;

  const AppColorPalette({
    required this.bg,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceHigh,
    required this.line,
    required this.lineSubtle,
    required this.ink,
    required this.muted,
    required this.inverseInk,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.sos,
    required this.sosDark,
    required this.sosSoft,
    required this.sosGlow,
    required this.info,
    required this.infoSoft,
    required this.violet,
    required this.violetSoft,
    required this.btnBg,
    required this.btnInk,
    required this.isEmergency,
  });

  /// Modo Normal: Cálido, comunitario, limpio y accesible
  static const AppColorPalette normal = AppColorPalette(
    bg: Color(0xFFF1F6FC),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF7FAFD),
    surfaceHigh: Color(0xFFEAF1F8),
    line: Color(0xFFE9EEF4),
    lineSubtle: Color(0xFFF0F4F8),
    ink: Color(0xFF0B2D6B),
    muted: Color(0xFF52627F),
    inverseInk: Colors.white,
    primary: Color(0xFF00A38E),
    primaryDark: Color(0xFF00796B),
    primarySoft: Color(0xFFE0F7F3),
    accent: Color(0xFFF2A93B),
    accentDark: Color(0xFFB06F0A),
    accentSoft: Color(0xFFFDF1DC),
    sos: Color(0xFFE0344A),
    sosDark: Color(0xFFAD1A2E),
    sosSoft: Color(0xFFFCE5E8),
    sosGlow: Color(0x33E0344A),
    info: Color(0xFF1C6FB0),
    infoSoft: Color(0xFFE3F2FB),
    violet: Color(0xFF2E57B8),
    violetSoft: Color(0xFFE6EEFB),
    btnBg: Color(0xFF0B2D6B),
    btnInk: Colors.white,
    isEmergency: false,
  );

  /// Modo Emergencia: Oscuro táctico de alto contraste para ahorro crítico de batería
  /// (OLED true blacks) y máxima visibilidad de alertas y coordenadas de rescate.
  static const AppColorPalette emergency = AppColorPalette(
    bg: Color(0xFF041128),
    surface: Color(0xFF0B2148),
    surfaceSubtle: Color(0xFF0F2852),
    surfaceHigh: Color(0xFF15336A),
    line: Color(0xFF213F78),
    lineSubtle: Color(0xFF183466),
    ink: Color(0xFFF1F6FC),
    muted: Color(0xFFA6B8D4),
    inverseInk: Color(0xFF041128),
    primary: Color(0xFF00BFA6),
    primaryDark: Color(0xFF6FE6D6),
    primarySoft: Color(0x3300BFA6),
    accent: Color(0xFFFFC837),
    accentDark: Color(0xFFFFD97D),
    accentSoft: Color(0x26FFC837),
    sos: Color(0xFFFF334B),
    sosDark: Color(0xFFFF6678),
    sosSoft: Color(0x33FF334B),
    sosGlow: Color(0x66FF334B),
    info: Color(0xFFB9E0F5),
    infoSoft: Color(0x26B9E0F5),
    violet: Color(0xFF9DB8F5),
    violetSoft: Color(0x269DB8F5),
    btnBg: Color(0xFFFF334B),
    btnInk: Colors.white,
    isEmergency: true,
  );
}

/// Unified Theme Provider built on Emil Kowalski's Design System
class AppTheme {
  final AppColorPalette palette;
  final bool highContrast;
  final bool largeText;

  const AppTheme({
    required this.palette,
    this.highContrast = false,
    this.largeText = false,
  });

  factory AppTheme.fromSettings({
    required bool isEmergency,
    required bool highContrast,
    required bool largeText,
  }) {
    final basePalette = isEmergency
        ? AppColorPalette.emergency
        : AppColorPalette.normal;

    return AppTheme(
      palette: basePalette,
      highContrast: highContrast,
      largeText: largeText,
    );
  }

  ThemeData toMaterialTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: palette.isEmergency ? Brightness.dark : Brightness.light,
        surface: palette.surface,
        onSurface: palette.ink,
        outline: palette.line,
      ),
      dividerColor: palette.line,
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          side: BorderSide(color: palette.line, width: 1.0),
        ),
      ),
    );
  }
}

