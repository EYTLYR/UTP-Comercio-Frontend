import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/nearby_logo.dart';

class SplashScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const SplashScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final light = !theme.dark && !theme.hc;
    final ink = light ? const Color(0xFF263B65) : theme.ink;
    final muted = light ? const Color(0xFF53627B) : theme.muted;
    final border = light ? const Color(0xFFE7E4DD) : theme.line;
    final yellow = light ? const Color(0xFFF2C14E) : theme.btnBg;
    final blueSoft = light ? const Color(0xFFEAF0FA) : theme.infoSoft;
    final panel = light ? ink : theme.surface2;
    final onPanel = light ? Colors.white : theme.ink;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0.0, constraints.maxHeight - 44),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: NearbyLogo(
                        width: 36,
                        inkColor: ink,
                        greenColor: light ? yellow : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby',
                            style: TextStyle(
                              color: ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Siempre cerca para ayudar',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu barrio,\nmás cerca.',
                        style: TextStyle(
                          color: onPanel,
                          fontSize: 36,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Servicios de confianza y ayuda entre vecinos.',
                        style: TextStyle(
                          color: onPanel,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ExcludeSemantics(
                        child: CustomPaint(
                          size: const Size(double.infinity, 104),
                          painter: _WelcomeNeighbors(
                            backdrop: onPanel.withValues(alpha: 0.18),
                            accent: light ? yellow : onPanel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (final (icon, label, iconSurface, color) in [
                  (
                    Icons.verified_user_outlined,
                    'Visto Bueno Vecinal',
                    blueSoft,
                    ink,
                  ),
                  (
                    Icons.favorite_border,
                    'Cadena de favores',
                    light ? const Color(0xFFFFF4D8) : theme.accentSoft,
                    ink,
                  ),
                  (
                    Icons.warning_amber_rounded,
                    'SOS en un gesto',
                    theme.sosSoft,
                    theme.sosDark,
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => state.go('login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: light ? ink : theme.btnInk,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: const Text(
                    'Ingresar con mi celular',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      '¿Eres de la municipalidad?',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    Semantics(
                      link: true,
                      child: InkWell(
                        onTap: () => state.go('muni-registro'),
                        mouseCursor: SystemMouseCursors.click,
                        splashFactory: NoSplash.splashFactory,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Regístrate aquí',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeNeighbors extends CustomPainter {
  const _WelcomeNeighbors({required this.backdrop, required this.accent});

  final Color backdrop;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 300, size.height / 104);
    canvas.save();
    canvas.translate((size.width - 300 * scale) / 2, 0);
    canvas.scale(scale);

    final paint = Paint()..color = backdrop;
    for (final x in [28.0, 214.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 16, 58, 82),
          const Radius.circular(29),
        ),
        paint,
      );
    }
    canvas.drawLine(
      const Offset(18, 98),
      const Offset(282, 98),
      paint..strokeWidth = 1.5,
    );

    _neighbor(
      canvas,
      center: 91,
      shirt: accent,
      skin: const Color(0xFFE6A478),
      hair: const Color(0xFF182340),
      waveToRight: true,
    );
    _neighbor(
      canvas,
      center: 208,
      shirt: const Color(0xFFA9C4EE),
      skin: const Color(0xFFC3815D),
      hair: const Color(0xFF182340),
      waveToRight: false,
    );

    paint
      ..color = accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(150, 23), const Offset(150, 15), paint);
    canvas.drawLine(const Offset(141, 27), const Offset(135, 22), paint);
    canvas.drawLine(const Offset(159, 27), const Offset(165, 22), paint);
    canvas.restore();
  }

  void _neighbor(
    Canvas canvas, {
    required double center,
    required Color shirt,
    required Color skin,
    required Color hair,
    required bool waveToRight,
  }) {
    final direction = waveToRight ? 1.0 : -1.0;
    final paint = Paint()..color = hair;
    canvas.drawOval(Rect.fromLTWH(center - 19, 20, 38, 47), paint);
    if (waveToRight) canvas.drawCircle(Offset(center - 15, 28), 9, paint);

    paint.color = shirt;
    canvas.drawRRect(
      RRect.fromLTRBR(
        center - 28,
        63,
        center + 28,
        98,
        const Radius.circular(13),
      ),
      paint,
    );
    final elbow = Offset(center + 36 * direction, 77);
    final wrist = Offset(center + 47 * direction, 50);
    paint
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center + 21 * direction, 72), elbow, paint);
    canvas.drawLine(elbow, wrist, paint..color = skin);
    canvas.drawCircle(wrist.translate(0, -4), 6, paint);
    canvas.drawRRect(
      RRect.fromLTRBR(center - 6, 55, center + 6, 67, const Radius.circular(3)),
      paint,
    );
    canvas.drawOval(Rect.fromLTWH(center - 14, 29, 28, 33), paint);
    paint.color = hair;
    canvas.drawArc(
      Rect.fromLTWH(center - 17, 21, 34, 25),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawCircle(Offset(center - 5, 44), 1.3, paint);
    canvas.drawCircle(Offset(center + 5, 44), 1.3, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromLTWH(center - 4, 48, 8, 5),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_WelcomeNeighbors oldDelegate) =>
      oldDelegate.backdrop != backdrop || oldDelegate.accent != accent;
}
