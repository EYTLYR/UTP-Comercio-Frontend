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
    bg: Color(0xFFF4F7F8),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF8FAFB),
    surfaceHigh: Color(0xFFEBF0F3),
    line: Color(0xFFDDE5EA),
    lineSubtle: Color(0xFFE8EEF2),
    ink: Color(0xFF15233A),
    muted: Color(0xFF5B687A),
    inverseInk: Colors.white,
    primary: Color(0xFF00A07F),
    primaryDark: Color(0xFF00664F),
    primarySoft: Color(0xFFDDF3EC),
    accent: Color(0xFFF0A93A),
    accentDark: Color(0xFFB06F0A),
    accentSoft: Color(0xFFFDF0D9),
    sos: Color(0xFFE0344A),
    sosDark: Color(0xFFAD1A2E),
    sosSoft: Color(0xFFFCE5E8),
    sosGlow: Color(0x33E0344A),
    info: Color(0xFF2F6FE4),
    infoSoft: Color(0xFFE4EDFD),
    violet: Color(0xFF6A55C8),
    violetSoft: Color(0xFFECE8FA),
    btnBg: Color(0xFF15233A),
    btnInk: Colors.white,
    isEmergency: false,
  );

  /// Modo Emergencia: Oscuro táctico de alto contraste para ahorro crítico de batería
  /// (OLED true blacks) y máxima visibilidad de alertas y coordenadas de rescate.
  static const AppColorPalette emergency = AppColorPalette(
    bg: Color(0xFF080D18),
    surface: Color(0xFF0F1726),
    surfaceSubtle: Color(0xFF142034),
    surfaceHigh: Color(0xFF1B2A44),
    line: Color(0xFF263753),
    lineSubtle: Color(0xFF1C2B42),
    ink: Color(0xFFF1F5F9),
    muted: Color(0xFF94A3B8),
    inverseInk: Color(0xFF080D18),
    primary: Color(0xFF2BC79F),
    primaryDark: Color(0xFF65FFD0),
    primarySoft: Color(0x332BC79F),
    accent: Color(0xFFFFC837),
    accentDark: Color(0xFFFFD97D),
    accentSoft: Color(0x26FFC837),
    sos: Color(0xFFFF334B),
    sosDark: Color(0xFFFF6678),
    sosSoft: Color(0x33FF334B),
    sosGlow: Color(0x66FF334B),
    info: Color(0xFF60A5FA),
    infoSoft: Color(0x2660A5FA),
    violet: Color(0xFFA78BFA),
    violetSoft: Color(0x26A78BFA),
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
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          side: BorderSide(color: palette.line, width: 1.0),
        ),
      ),
    );
  }
}

