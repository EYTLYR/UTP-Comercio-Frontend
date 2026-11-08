import 'package:flutter/material.dart';

class NeighborhoodPainter extends CustomPainter {
  const NeighborhoodPainter({
    required this.sun,
    required this.houses,
    required this.roofs,
    required this.windows,
  });

  final Color sun;
  final Color houses;
  final Color roofs;
  final Color windows;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 96);
    final paint = Paint()..color = sun;
    canvas.drawCircle(const Offset(235, 33), 27, paint);
    const buildings = [
      Rect.fromLTWH(5, 52, 52, 39),
      Rect.fromLTWH(66, 41, 60, 50),
      Rect.fromLTWH(136, 55, 49, 36),
      Rect.fromLTWH(196, 45, 59, 46),
      Rect.fromLTWH(266, 57, 29, 34),
    ];
    for (final (index, house) in buildings.indexed) {
      paint.color = houses;
      canvas.drawRect(house, paint);
      paint.color = index.isOdd ? sun : roofs;
      canvas.drawPath(
        Path()
          ..moveTo(house.left - 3, house.top)
          ..lineTo(house.center.dx, house.top - 14)
          ..lineTo(house.right + 3, house.top)
          ..close(),
        paint,
      );
      paint.color = windows;
      canvas.drawRect(Rect.fromLTWH(house.center.dx - 4, 76, 8, 15), paint);
      canvas.drawRect(
        Rect.fromLTWH(house.left + 7, house.top + 7, 6, 8),
        paint,
      );
    }
    paint.color = roofs;
    canvas.drawLine(const Offset(5, 92), const Offset(295, 92), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(NeighborhoodPainter oldDelegate) =>
      oldDelegate.sun != sun ||
      oldDelegate.houses != houses ||
      oldDelegate.roofs != roofs ||
      oldDelegate.windows != windows;
}
