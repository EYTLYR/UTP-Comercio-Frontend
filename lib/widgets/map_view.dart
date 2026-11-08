import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/nearby_theme.dart';

class NearbyMapView extends StatelessWidget {
  final NearbyThemeData theme;
  final bool emergency;
  final List<MapPin> pins;
  final String? selectedPinId;
  final ValueChanged<String>? onPinSelected;
  final bool showRoute;
  final Color? routeColor;
  final IconData? routeDestIcon;

  const NearbyMapView({
    super.key,
    required this.theme,
    required this.emergency,
    required this.pins,
    this.selectedPinId,
    this.onPinSelected,
    this.showRoute = false,
    this.routeColor,
    this.routeDestIcon,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Map Vector Background
            Positioned.fill(
              child: CustomPaint(
                painter: _MapVectorPainter(
                  textScaler: MediaQuery.textScalerOf(context),
                  theme: theme,
                  emergency: emergency,
                  showRoute: showRoute,
                  routeColor:
                      routeColor ??
                      (emergency ? NearbyColors.sos : NearbyColors.primary),
                  routeDestIcon: routeDestIcon,
                ),
              ),
            ),

            // Pins
            ...pins.map((pin) {
              final isSel = selectedPinId == pin.id;
              final pinColor = _getPinColor(pin.kind);
              final left = (pin.x / 100.0) * w;
              final top = (pin.y / 100.0) * h;
              final size = isSel ? 52.0 : 42.0;

              return Positioned(
                left: left - (size / 2),
                top: top - (size / 2),
                child: GestureDetector(
                  onTap: () => onPinSelected?.call(pin.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: pinColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSel ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isSel ? 0.35 : 0.22,
                          ),
                          blurRadius: isSel ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        pin.icon,
                        color: Colors.white,
                        size: isSel ? 26 : 22,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Me dot
            Positioned(
              left: (w * 0.5) - 12,
              top: (h * 0.5) - 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: NearbyColors.info,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: NearbyColors.info.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 6,
                    ),
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getPinColor(String kind) {
    switch (kind) {
      case 'svc':
        return NearbyColors.navy;
      case 'need':
        return NearbyColors.accent;
      case 'offer':
        return NearbyColors.primary;
      case 'vuln':
        return NearbyColors.sos;
      case 'safe':
        return NearbyColors.info;
      case 'res':
        return NearbyColors.accent;
      case 'group':
        return NearbyColors.violet;
      default:
        return NearbyColors.primary;
    }
  }
}

class _MapVectorPainter extends CustomPainter {
  final TextScaler textScaler;
  final NearbyThemeData theme;
  final bool emergency;
  final bool showRoute;
  final Color routeColor;
  final IconData? routeDestIcon;

  _MapVectorPainter({
    required this.textScaler,
    required this.theme,
    required this.emergency,
    required this.showRoute,
    required this.routeColor,
    this.routeDestIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas background
    final bgPaint = Paint()..color = theme.mapBg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Scale from reference 400x640
    final sx = size.width / 400.0;
    final sy = size.height / 640.0;

    canvas.save();
    canvas.scale(sx, sy);

    // Park
    final parkPaint = Paint()..color = theme.mapPark;
    final parkRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 292, 98, 104),
      const Radius.circular(14),
    );
    canvas.drawRRect(parkRect, parkPaint);

    // Park text
    _drawText(
      canvas,
      'Parque',
      101,
      350,
      fontSize: 11,
      color: theme.primaryDark,
      bold: true,
      center: true,
    );

    // Streets
    final streetPaint = Paint()
      ..color = theme.mapStreet
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Av. Principal (thick)
    streetPaint.strokeWidth = 24;
    canvas.drawLine(const Offset(0, 220), const Offset(400, 220), streetPaint);

    // Other horizontals
    streetPaint.strokeWidth = 12;
    canvas.drawLine(const Offset(0, 90), const Offset(400, 90), streetPaint);
    canvas.drawLine(const Offset(0, 420), const Offset(400, 420), streetPaint);
    canvas.drawLine(const Offset(0, 540), const Offset(400, 540), streetPaint);

    // Verticals
    canvas.drawLine(const Offset(40, 0), const Offset(40, 640), streetPaint);
    canvas.drawLine(const Offset(160, 0), const Offset(160, 640), streetPaint);
    canvas.drawLine(const Offset(270, 0), const Offset(270, 640), streetPaint);
    canvas.drawLine(const Offset(370, 0), const Offset(370, 640), streetPaint);

    // Diagonal
    streetPaint.strokeWidth = 9;
    canvas.drawLine(
      const Offset(160, 420),
      const Offset(270, 540),
      streetPaint,
    );

    // Street labels
    _drawText(
      canvas,
      'Av. Principal',
      320,
      214,
      fontSize: 10,
      color: theme.mapLabel,
      bold: true,
      center: true,
    );
    _drawText(
      canvas,
      'Jr. Los Pinos',
      215,
      86,
      fontSize: 9,
      color: theme.mapLabel,
      bold: true,
      center: true,
    );
    _drawText(
      canvas,
      'Jr. Las Flores',
      215,
      416,
      fontSize: 9,
      color: theme.mapLabel,
      bold: true,
      center: true,
    );

    // Range radius circle
    final rangePaint = Paint()
      ..color = (emergency ? const Color(0xFFE0344A) : const Color(0xFF00A38E))
          .withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(200, 320), 150, rangePaint);

    final rangeBorder = Paint()
      ..color = (emergency ? const Color(0xFFE0344A) : const Color(0xFF00A38E))
          .withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawDashedCircle(canvas, const Offset(200, 320), 150, rangeBorder);

    // Route if active
    if (showRoute) {
      final routePaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final routePath = Path()
        ..moveTo(200, 320)
        ..lineTo(160, 320)
        ..lineTo(160, 220)
        ..lineTo(270, 220)
        ..lineTo(270, 150);

      _drawDashedPath(canvas, routePath, routePaint);

      // Destination target point
      final destPaint = Paint()
        ..color = routeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(270, 150), 22, destPaint);

      final destBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(const Offset(270, 150), 22, destBorder);

      if (routeDestIcon != null) {
        final iconSpan = TextSpan(
          text: String.fromCharCode(routeDestIcon!.codePoint),
          style: TextStyle(
            fontFamily: routeDestIcon!.fontFamily,
            package: routeDestIcon!.fontPackage,
            color: Colors.white,
            fontSize: 22,
          ),
        );
        final iconPainter = TextPainter(
          text: iconSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        iconPainter.paint(
          canvas,
          Offset(270 - (iconPainter.width / 2), 150 - (iconPainter.height / 2)),
        );
      }
    }

    canvas.restore();
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashCount = 36;
    const sweep = (2 * 3.14159) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep,
        false,
        paint,
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 10;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 18;
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y, {
    required double fontSize,
    required Color color,
    bool bold = false,
    bool center = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: color,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final offset = center
        ? Offset(x - (painter.width / 2), y - (painter.height / 2))
        : Offset(x, y);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MapVectorPainter oldDelegate) =>
      oldDelegate.textScaler != textScaler ||
      oldDelegate.theme != theme ||
      oldDelegate.emergency != emergency ||
      oldDelegate.showRoute != showRoute ||
      oldDelegate.routeColor != routeColor;
}
