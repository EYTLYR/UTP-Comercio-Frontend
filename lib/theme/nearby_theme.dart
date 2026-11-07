import 'package:flutter/material.dart';

class NearbyColors {
  // Brand tokens
  static const Color stage = Color(0xFFE4EAEE);
  static const Color navy = Color(0xFF15233A);
  static const Color navy2 = Color(0xFF22344F);
  static const Color green = Color(0xFF00A07F);

  // Normal theme
  static const Color bg = Color(0xFFF4F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEBF0F3);
  static const Color ink = Color(0xFF15233A);
  static const Color muted = Color(0xFF5B687A);
  static const Color line = Color(0xFFDDE5EA);

  static const Color primary = Color(0xFF00A07F);
  static const Color primaryDark = Color(0xFF00664F);
  static const Color primarySoft = Color(0xFFDDF3EC);

  static const Color btnBg = Color(0xFF15233A);
  static const Color btnInk = Color(0xFFFFFFFF);

  static const Color accent = Color(0xFFF0A93A);
  static const Color accentInk = Color(0xFF7A4E00);
  static const Color accentSoft = Color(0xFFFDF0D9);

  static const Color sos = Color(0xFFE0344A);
  static const Color sosDark = Color(0xFFAD1A2E);
  static const Color sosSoft = Color(0xFFFCE5E8);

  static const Color info = Color(0xFF2F6FE4);
  static const Color infoSoft = Color(0xFFE4EDFD);

  static const Color violet = Color(0xFF6A55C8);
  static const Color violetSoft = Color(0xFFECE8FA);
  static const Color ai = Color(0xFF6A55C8);
  static const Color aiSoft = Color(0xFFECE8FA);

  static const Color swOff = Color(0xFFC9D2DA);

  // Dark theme
  static const Color darkBg = Color(0xFF0C1524);
  static const Color darkSurface = Color(0xFF142038);
  static const Color darkSurface2 = Color(0xFF1B2945);
  static const Color darkInk = Color(0xFFE8EEF6);
  static const Color darkMuted = Color(0xFF9AA9BE);
  static const Color darkLine = Color(0xFF25355A);

  static const Color darkPrimary = Color(0xFF2BC79F);
  static const Color darkPrimaryDark = Color(0xFF7BE3C6);
  static const Color darkPrimarySoft = Color(0x292BC79F);

  static const Color darkBtnBg = Color(0xFF2BC79F);
  static const Color darkBtnInk = Color(0xFF0B1424);

  static const Color darkAccent = Color(0xFFF4B652);
  static const Color darkAccentInk = Color(0xFFF7CD85);
  static const Color darkAccentSoft = Color(0x26F4B652);

  static const Color darkSos = Color(0xFFEF4359);
  static const Color darkSosDark = Color(0xFFFF9AA6);
  static const Color darkSosSoft = Color(0x2BEF4359);

  static const Color darkInfo = Color(0xFF7FA6FF);
  static const Color darkInfoSoft = Color(0x267FA6FF);

  static const Color darkViolet = Color(0xFFB4A6FF);
  static const Color darkVioletSoft = Color(0x26B4A6FF);

  static const Color darkNavy = Color(0xFF08101D);

  // Map colors
  static const Color mapBg = Color(0xFFE6EDEF);
  static const Color mapStreet = Color(0xFFFFFFFF);
  static const Color mapPark = Color(0xFFCBEBDD);
  static const Color mapLabel = Color(0xFF7C8898);

  static const Color darkMapBg = Color(0xFF111D31);
  static const Color darkMapStreet = Color(0xFF22324F);
  static const Color darkMapPark = Color(0xFF143A31);
  static const Color darkMapLabel = Color(0xFF7D8DA6);
}

class NearbyThemeData {
  final bool dark;
  final bool lg;
  final bool hc;
  final bool emergency;

  NearbyThemeData({
    required this.dark,
    required this.lg,
    required this.hc,
    required this.emergency,
  });

  factory NearbyThemeData.build({
    required bool dark,
    required bool lg,
    required bool hc,
    required bool emergency,
  }) {
    return NearbyThemeData(dark: dark, lg: lg, hc: hc, emergency: emergency);
  }

  Color get ai => violet;
  Color get aiSoft => violetSoft;

  Color get bg => hc
      ? (dark ? Colors.black : Colors.white)
      : (dark ? NearbyColors.darkBg : NearbyColors.bg);
  Color get surface => hc
      ? (dark ? const Color(0xFF080808) : Colors.white)
      : (dark ? NearbyColors.darkSurface : NearbyColors.surface);
  Color get surface2 => hc
      ? (dark ? const Color(0xFF202020) : const Color(0xFFE8E8E8))
      : (dark ? NearbyColors.darkSurface2 : NearbyColors.surface2);
  Color get ink => hc
      ? (dark ? Colors.white : Colors.black)
      : (dark ? NearbyColors.darkInk : NearbyColors.ink);
  Color get muted => hc
      ? (dark ? Colors.white : Colors.black)
      : (dark ? NearbyColors.darkMuted : NearbyColors.muted);
  Color get line => hc
      ? (dark ? const Color(0xFFE8E8E8) : const Color(0xFF222222))
      : (dark ? NearbyColors.darkLine : NearbyColors.line);

  Color get primary => hc
      ? (dark ? const Color(0xFF65FFD0) : const Color(0xFF00543F))
      : (dark ? NearbyColors.darkPrimary : NearbyColors.primary);
  Color get primaryDark => hc
      ? (dark ? const Color(0xFF8AFFDB) : const Color(0xFF00382B))
      : (dark ? NearbyColors.darkPrimaryDark : NearbyColors.primaryDark);
  Color get primarySoft =>
      dark ? NearbyColors.darkPrimarySoft : NearbyColors.primarySoft;

  Color get btnBg => hc
      ? (dark ? Colors.white : Colors.black)
      : (dark ? NearbyColors.darkBtnBg : NearbyColors.btnBg);
  Color get btnInk => hc
      ? (dark ? Colors.black : Colors.white)
      : (dark ? NearbyColors.darkBtnInk : NearbyColors.btnInk);

  Color get accent => dark ? NearbyColors.darkAccent : NearbyColors.accent;
  Color get accentInk =>
      dark ? NearbyColors.darkAccentInk : NearbyColors.accentInk;
  Color get accentSoft =>
      dark ? NearbyColors.darkAccentSoft : NearbyColors.accentSoft;

  Color get sos => dark ? NearbyColors.darkSos : NearbyColors.sos;
  Color get sosDark => dark ? NearbyColors.darkSosDark : NearbyColors.sosDark;
  Color get sosSoft => dark ? NearbyColors.darkSosSoft : NearbyColors.sosSoft;

  Color get info => dark ? NearbyColors.darkInfo : NearbyColors.info;
  Color get infoSoft =>
      dark ? NearbyColors.darkInfoSoft : NearbyColors.infoSoft;

  Color get violet => dark ? NearbyColors.darkViolet : NearbyColors.violet;
  Color get violetSoft =>
      dark ? NearbyColors.darkVioletSoft : NearbyColors.violetSoft;

  Color get mapBg => dark ? NearbyColors.darkMapBg : NearbyColors.mapBg;
  Color get mapStreet =>
      dark ? NearbyColors.darkMapStreet : NearbyColors.mapStreet;
  Color get mapPark => dark ? NearbyColors.darkMapPark : NearbyColors.mapPark;
  Color get mapLabel =>
      dark ? NearbyColors.darkMapLabel : NearbyColors.mapLabel;

  Color get logoInk => dark ? NearbyColors.darkInk : NearbyColors.navy;

  ThemeData get materialTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      contrastLevel: hc ? 1 : 0,
    ).copyWith(surface: surface, onSurface: ink, outline: line),
    dividerColor: line,
  );

  double get scaleFactor => lg ? 1.4 : 1.0;
}

/// Preserve system text accessibility and multiply every font by the app setting.
class NearbyTextScaler extends TextScaler {
  final TextScaler system;
  final double factor;
  const NearbyTextScaler(this.system, this.factor);
  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;
  @override
  double get textScaleFactor => system.scale(16) / 16 * factor;
  @override
  bool operator ==(Object other) =>
      other is NearbyTextScaler &&
      system == other.system &&
      factor == other.factor;
  @override
  int get hashCode => Object.hash(system, factor);
}
