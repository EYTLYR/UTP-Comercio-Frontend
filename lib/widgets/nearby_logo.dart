import 'package:flutter/material.dart';

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
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _NearbyLogoPainter(
          inkColor: inkColor ?? const Color(0xFF15233A),
          gapColor: gapColor ?? Colors.white,
          greenColor: greenColor ?? const Color(0xFF00A07F),
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

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);

    // Green person head
    final greenHeadPaint = Paint()
      ..color = greenColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(73, 17), 10.5, greenHeadPaint);

    // Green person body curve
    final greenBodyPaint = Paint()
      ..color = greenColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;

    final greenPath = Path();
    greenPath.moveTo(61, 44);
    greenPath.cubicTo(76, 33, 95, 42, 91, 59);
    greenPath.cubicTo(88, 71, 75, 79, 60, 71);
    canvas.drawPath(greenPath, greenBodyPaint);

    // Gap path (stroke)
    final gapPaint = Paint()
      ..color = gapColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.round;

    final gapPath = Path();
    gapPath.moveTo(46, 38);
    gapPath.lineTo(62, 50);
    gapPath.cubicTo(66, 53, 71, 53, 74, 49);
    canvas.drawPath(gapPath, gapPaint);

    // Navy person head
    final inkHeadPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(31, 15), 11.5, inkHeadPaint);

    // Navy person body & arm
    final inkBodyPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inkPath = Path();
    inkPath.moveTo(24, 72);
    inkPath.lineTo(24, 46);
    inkPath.cubicTo(24, 34, 36, 30, 45, 37);
    inkPath.lineTo(62, 50);
    inkPath.cubicTo(66, 53, 71, 53, 74, 49);
    canvas.drawPath(inkPath, inkBodyPaint);

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
        NearbyLogo(
          width: width * 0.62,
          inkColor: inkColor,
          gapColor: gapColor,
        ),
        const SizedBox(height: 14),
        Text(
          'Nearby',
          style: TextStyle(
            fontSize: width * 0.21,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: inkColor ?? const Color(0xFF15233A),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
