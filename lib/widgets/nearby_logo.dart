import 'package:flutter/material.dart';

import '../theme/nearby_theme.dart';

/// Isotipo de Nearby: una mano abierta que sostiene un corazón.
///
/// La mano va en azul marino ([inkColor]) y el corazón en turquesa ([greenColor]);
/// [gapColor] es el contorno que separa ambas figuras (el color del fondo donde se pinta).
/// Dibujado en vector para que se vea nítido en cualquier tamaño.
class NearbyLogo extends StatelessWidget {
  final double width;
  final Color? inkColor;
  final Color? gapColor;
  final Color? greenColor;

  const NearbyLogo({
    super.key,
    this.width = 40,
    this.inkColor,
    this.gapColor,
    this.greenColor,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 0.84;
    return Semantics(
      label: 'Nearby',
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _NearbyLogoPainter(
            inkColor: inkColor ?? NearbyColors.brandNavy,
            gapColor: gapColor ?? Colors.white,
            greenColor: greenColor ?? NearbyColors.brandTurquoise,
          ),
        ),
      ),
    );
  }
}

class _NearbyLogoPainter extends CustomPainter {
  final Color inkColor;
  final Color gapColor;
  final Color greenColor;

  _NearbyLogoPainter({
    required this.inkColor,
    required this.gapColor,
    required this.greenColor,
  });

  /// Corazón que descansa sobre la palma (lienzo de 100 × 84).
  static Path _heart() => Path()
    ..moveTo(47, 54)
    ..cubicTo(27, 43, 20, 30, 27, 20)
    ..cubicTo(33, 12, 42, 13, 47, 21)
    ..cubicTo(52, 13, 61, 12, 67, 20)
    ..cubicTo(74, 30, 67, 43, 47, 54)
    ..close();

  /// Dedos extendidos (inicio, punta, grosor), de arriba hacia abajo.
  static const _fingers = [
    (Offset(58, 60), Offset(88, 47), 10.0),
    (Offset(60, 67), Offset(93, 58), 10.0),
    (Offset(58, 74), Offset(90, 69), 9.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 100, 84));

    final ink = Paint()
      ..color = inkColor
      ..isAntiAlias = true;
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Mano abierta, palma hacia arriba: muñeca, palma, pulgar y dedos.
    canvas.drawLine(
      const Offset(28, 74),
      const Offset(22, 92),
      stroke(inkColor, 18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 56, 52, 22),
        const Radius.circular(11),
      ),
      ink,
    );
    canvas.drawLine(
      const Offset(26, 64),
      const Offset(14, 50),
      stroke(inkColor, 12),
    );
    for (final (start, tip, width) in _fingers) {
      // Un trazo del color del fondo, un poco más ancho, separa cada dedo del anterior.
      canvas.drawLine(start, tip, stroke(gapColor, width + 3));
      canvas.drawLine(start, tip, stroke(inkColor, width));
    }

    final heart = _heart();
    // Contorno del color del fondo: separa el corazón de la mano (figura y fondo).
    canvas.drawPath(
      heart,
      Paint()
        ..color = gapColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      heart,
      Paint()
        ..color = greenColor
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NearbyLogoPainter oldDelegate) =>
      oldDelegate.inkColor != inkColor ||
      oldDelegate.gapColor != gapColor ||
      oldDelegate.greenColor != greenColor;
}

class NearbyWordmark extends StatelessWidget {
  final double width;
  final Color? inkColor;
  final Color? gapColor;

  const NearbyWordmark({
    super.key,
    this.width = 220,
    this.inkColor,
    this.gapColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NearbyLogo(width: width * 0.62, inkColor: inkColor, gapColor: gapColor),
        const SizedBox(height: 14),
        Text(
          'Nearby',
          style: TextStyle(
            fontFamily: NearbyThemeData.fontFamily,
            fontSize: width * 0.21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: inkColor ?? NearbyColors.brandNavy,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
