import 'package:flutter/material.dart';

/// Identidad visual de Nearby · "Siempre cerca para ayudar".
///
/// Paleta oficial (base de todo el tema):
///   Azul marino  #0B2D6B  color principal: títulos, textos, botones principales.
///   Turquesa     #00BFA6  acento: estados activos, confirmaciones, selección.
///   Celeste      #B9E0F5  elementos secundarios.
///   Azul claro   #F1F6FC  fondos y superficies.
///   Blanco       #FFFFFF  tarjetas.
///   Gris claro   #E9EEF4  bordes y separadores.
///
/// Los demás tonos son derivados de esa paleta (más oscuros o más suaves) para cumplir
/// contraste. Rojo (SOS) y ámbar (aviso) se conservan solo como colores de estado: en una app
/// de emergencias su significado no se puede cambiar.
class NearbyColors {
  // Paleta oficial
  static const Color brandNavy = Color(0xFF0B2D6B);
  static const Color brandTurquoise = Color(0xFF00BFA6);
  static const Color brandCeleste = Color(0xFFB9E0F5);
  static const Color brandMist = Color(0xFFF1F6FC);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color brandCloud = Color(0xFFE9EEF4);

  // Brand tokens (nombres históricos que usa toda la app)
  static const Color stage = brandCloud;
  static const Color navy = brandNavy;
  static const Color navy2 = Color(0xFF163F8A);
  static const Color green = brandTurquoise;

  // Tema claro
  static const Color bg = brandMist;
  static const Color surface = brandWhite;
  static const Color surface2 = Color(0xFFEAF1F8);
  static const Color ink = brandNavy;
  static const Color muted = Color(0xFF52627F);
  static const Color line = brandCloud;

  /// Borde de campos y controles: más visible que [line] (contraste ≥ 3:1 con el fondo).
  static const Color lineStrong = Color(0xFFB4C3D6);

  /// Turquesa para íconos y trazos sobre fondo claro (≥ 3:1 sobre blanco).
  static const Color primary = Color(0xFF00A38E);

  /// Turquesa profundo para textos sobre fondo claro (≥ 4.5:1 sobre blanco).
  static const Color primaryDark = Color(0xFF00796B);
  static const Color primarySoft = Color(0xFFE0F7F3);

  /// Texto sobre rellenos turquesa: azul marino (5.6:1), nunca blanco (2.3:1).
  static const Color onPrimary = brandNavy;

  static const Color btnBg = brandNavy;
  static const Color btnInk = brandWhite;

  // Aviso (estado): ámbar.
  static const Color accent = Color(0xFFF2A93B);
  static const Color accentInk = Color(0xFF7A4E00);
  static const Color accentSoft = Color(0xFFFDF1DC);

  // Emergencia (estado): rojo.
  static const Color sos = Color(0xFFE0344A);
  static const Color sosDark = Color(0xFFAD1A2E);
  static const Color sosSoft = Color(0xFFFCE7EA);

  // Información: celeste profundo.
  static const Color info = Color(0xFF1C6FB0);
  static const Color infoSoft = Color(0xFFE3F2FB);

  // Asistente IA: azul de la marca, un paso más claro que el marino.
  static const Color violet = Color(0xFF2E57B8);
  static const Color violetSoft = Color(0xFFE6EEFB);
  static const Color ai = violet;
  static const Color aiSoft = violetSoft;

  static const Color swOff = Color(0xFFC9D4E2);

  // Tema oscuro (azul marino profundo)
  static const Color darkBg = Color(0xFF061736);
  static const Color darkSurface = Color(0xFF0D2552);
  static const Color darkSurface2 = Color(0xFF143166);
  static const Color darkInk = brandMist;
  static const Color darkMuted = Color(0xFFA6B8D4);
  static const Color darkLine = Color(0xFF213F78);

  static const Color darkPrimary = brandTurquoise;
  static const Color darkPrimaryDark = Color(0xFF6FE6D6);
  static const Color darkPrimarySoft = Color(0x2900BFA6);

  static const Color darkBtnBg = brandTurquoise;
  static const Color darkBtnInk = brandNavy;

  static const Color darkAccent = Color(0xFFF4B652);
  static const Color darkAccentInk = Color(0xFFF7CD85);
  static const Color darkAccentSoft = Color(0x26F4B652);

  static const Color darkSos = Color(0xFFEF4359);
  static const Color darkSosDark = Color(0xFFFF9AA6);
  static const Color darkSosSoft = Color(0x2BEF4359);

  static const Color darkInfo = brandCeleste;
  static const Color darkInfoSoft = Color(0x26B9E0F5);

  static const Color darkViolet = Color(0xFF9DB8F5);
  static const Color darkVioletSoft = Color(0x269DB8F5);

  static const Color darkNavy = Color(0xFF041128);

  // Mapa
  static const Color mapBg = Color(0xFFE6EEF6);
  static const Color mapStreet = brandWhite;
  static const Color mapPark = Color(0xFFCDEFE9);
  static const Color mapLabel = Color(0xFF6B7C99);

  static const Color darkMapBg = Color(0xFF0B214A);
  static const Color darkMapStreet = Color(0xFF1A3769);
  static const Color darkMapPark = Color(0xFF0C3B45);
  static const Color darkMapLabel = Color(0xFF8094B8);
}

/// Escala de espaciado y radios compartida (múltiplos de 4).
class NearbySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen lateral de todas las pantallas.
  static const double gutter = 16;
}

class NearbyRadius {
  /// Chips internos, insignias.
  static const double sm = 10;

  /// Botones y campos de texto: el mismo radio para todo lo que se toca.
  static const double control = 14;

  /// Tarjetas y paneles.
  static const double card = 18;

  /// Hojas inferiores y diálogos.
  static const double sheet = 24;
  static const double pill = 999;
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

  static const String fontFamily = 'Poppins';

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

  /// Borde de campos y controles (más marcado que [line]).
  Color get lineStrong =>
      hc ? line : (dark ? const Color(0xFF34558F) : NearbyColors.lineStrong);

  Color get primary => hc
      ? (dark ? const Color(0xFF65FFD0) : const Color(0xFF00543F))
      : (dark ? NearbyColors.darkPrimary : NearbyColors.primary);
  Color get primaryDark => hc
      ? (dark ? const Color(0xFF8AFFDB) : const Color(0xFF00382B))
      : (dark ? NearbyColors.darkPrimaryDark : NearbyColors.primaryDark);
  Color get primarySoft =>
      dark ? NearbyColors.darkPrimarySoft : NearbyColors.primarySoft;

  /// Texto e íconos sobre un relleno [primary].
  Color get onPrimary =>
      hc ? (dark ? Colors.black : Colors.white) : NearbyColors.onPrimary;

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

  /// Sombra suave y de dos capas para tarjetas (figura sobre fondo sin bordes duros).
  List<BoxShadow> get cardShadow => dark || hc
      ? const []
      : [
          BoxShadow(
            color: NearbyColors.brandNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: NearbyColors.brandNavy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];

  /// Jerarquía tipográfica: 4 pesos (400/500/600/700) y una escala corta.
  TextTheme get _textTheme {
    TextStyle s(
      double size,
      FontWeight w, {
      Color? c,
      double h = 1.35,
      double ls = 0,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: w,
      height: h,
      letterSpacing: ls,
      color: c ?? ink,
    );
    return TextTheme(
      displaySmall: s(28, FontWeight.w700, h: 1.15, ls: -0.6),
      headlineMedium: s(24, FontWeight.w700, h: 1.2, ls: -0.4),
      headlineSmall: s(22, FontWeight.w700, h: 1.2, ls: -0.4),
      titleLarge: s(20, FontWeight.w700, h: 1.25, ls: -0.3),
      titleMedium: s(16, FontWeight.w600, h: 1.3, ls: -0.1),
      titleSmall: s(14, FontWeight.w600, h: 1.3),
      bodyLarge: s(15, FontWeight.w400, h: 1.45),
      bodyMedium: s(14, FontWeight.w400, h: 1.45),
      bodySmall: s(12, FontWeight.w400, c: muted, h: 1.4),
      labelLarge: s(15, FontWeight.w600, h: 1.2, ls: 0.1),
      labelMedium: s(13, FontWeight.w500, h: 1.2),
      labelSmall: s(11, FontWeight.w500, c: muted, h: 1.2, ls: 0.2),
    );
  }

  ThemeData get materialTheme {
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NearbyRadius.control),
    );
    const buttonText = TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    // 48 dp: área táctil cómoda (accesibilidad).
    const minButton = Size(64, 48);
    final focusRing = hc ? ink : primary;

    OutlineInputBorder field(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(NearbyRadius.control),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: NearbyColors.brandNavy,
            brightness: dark ? Brightness.dark : Brightness.light,
            contrastLevel: hc ? 1 : 0,
          ).copyWith(
            primary: dark ? primary : NearbyColors.brandNavy,
            onPrimary: dark ? NearbyColors.brandNavy : Colors.white,
            secondary: primary,
            onSecondary: onPrimary,
            tertiary: info,
            error: sos,
            surface: surface,
            onSurface: ink,
            onSurfaceVariant: muted,
            outline: lineStrong,
            outlineVariant: line,
          ),
      textTheme: _textTheme,
      dividerColor: line,
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: ink, size: 22),

      // Botón principal: azul marino lleno. Mismo alto, radio y peso en toda la app.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnBg,
          foregroundColor: btnInk,
          disabledBackgroundColor: line,
          disabledForegroundColor: muted,
          elevation: 0,
          minimumSize: minButton,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: btnBg,
          foregroundColor: btnInk,
          disabledBackgroundColor: line,
          disabledForegroundColor: muted,
          minimumSize: minButton,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      // Botón secundario: contorno, mismo tamaño que el principal.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: lineStrong, width: 1.2),
          minimumSize: minButton,
          padding: buttonPadding,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      // Acción terciaria: texto en azul (o turquesa en oscuro).
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? primary : NearbyColors.navy2,
          minimumSize: const Size(48, 40),
          shape: controlShape,
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(44, 44),
        ),
      ),

      // Campos: borde visible con el radio de los botones; el foco usa el color principal.
      // Solo se fija `border`: los campos sin borde (dentro de una tarjeta) siguen igual.
      inputDecorationTheme: InputDecorationTheme(
        border: field(lineStrong),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: muted,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: fontFamily,
          color: dark ? primary : NearbyColors.navy,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: muted.withValues(alpha: 0.8),
          fontWeight: FontWeight.w400,
        ),
        helperStyle: TextStyle(fontFamily: fontFamily, color: muted),
        errorStyle: TextStyle(
          fontFamily: fontFamily,
          color: sos,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: focusRing,
        selectionColor: primary.withValues(alpha: 0.3),
        selectionHandleColor: focusRing,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NearbyRadius.card),
          side: BorderSide(color: line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ink,
        textColor: ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NearbyRadius.card),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12.5,
          height: 1.4,
          color: muted,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primarySoft,
        disabledColor: surface2,
        checkmarkColor: dark ? primary : NearbyColors.primaryDark,
        side: BorderSide(color: line),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? primary : NearbyColors.primaryDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NearbyRadius.sheet),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.45,
          color: muted,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NearbyRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NearbyColors.brandNavy,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NearbyRadius.control),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: NearbyColors.brandNavy,
          borderRadius: BorderRadius.circular(NearbyRadius.sm),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: dark ? surface2 : NearbyColors.brandCloud,
        circularTrackColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
        checkColor: WidgetStatePropertyAll(onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : lineStrong,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : hc
              ? surface
              : dark
              ? const Color(0xFF26457D)
              : NearbyColors.swOff,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? dark
                    ? NearbyColors.brandNavy
                    : Colors.white
              : hc
              ? ink
              : dark
              ? const Color(0xFFE2E8F0)
              : Colors.white,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : hc
              ? ink
              : dark
              ? const Color(0xFF8DA3C6)
              : const Color(0xFF7A8BA6),
        ),
        trackOutlineWidth: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? 0
              : hc
              ? 2
              : 1.5,
        ),
      ),
    );
  }

  double get scaleFactor => lg ? 1.4 : 1.0;
}

/// Preserve system text accessibility and multiply every font by the app setting.
///
/// [brandOptical] compensa que Poppins es más ancha y alta que la fuente anterior: así los
/// tamaños escritos en cada pantalla ocupan el mismo espacio y nada se corta, sin perder
/// legibilidad (la altura de la x de Poppins sigue siendo mayor).
class NearbyTextScaler extends TextScaler {
  static const double brandOptical = 0.93;

  final TextScaler system;
  final double factor;
  const NearbyTextScaler(this.system, this.factor);
  @override
  double scale(double fontSize) =>
      system.scale(fontSize) * factor * brandOptical;
  @override
  double get textScaleFactor => system.scale(16) / 16 * factor * brandOptical;
  @override
  bool operator ==(Object other) =>
      other is NearbyTextScaler &&
      system == other.system &&
      factor == other.factor;
  @override
  int get hashCode => Object.hash(system, factor);
}

/// Palette for the screens that use the white Nearby layout.
class NearbyCommunityStyle {
  const NearbyCommunityStyle(this.theme);
  final NearbyThemeData theme;

  bool get light => !theme.dark && !theme.hc;
  Color get ink => light ? const Color(0xFF263B65) : theme.ink;
  Color get muted => light ? const Color(0xFF53627B) : theme.muted;
  Color get line => light ? const Color(0xFFE7E4DD) : theme.line;
  Color get ivory => light ? const Color(0xFFF7F4ED) : theme.surface2;
  Color get blueSoft => light ? const Color(0xFFEAF0FA) : theme.infoSoft;
  Color get accent => light ? const Color(0xFFF2C14E) : theme.btnBg;
  Color get onAccent => light ? ink : theme.btnInk;
  Color get panel => light ? ink : theme.surface2;
  Color get onPanel => light ? Colors.white : theme.ink;

  ButtonStyle action({bool filled = true}) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const text = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return filled
        ? ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: onAccent,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape: shape,
            textStyle: text,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: ink, width: 1.5),
            minimumSize: const Size(0, 48),
            shape: shape,
            textStyle: text,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          );
  }
}
