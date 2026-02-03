import 'dart:math';
import 'package:flutter/material.dart';
import '../services/shapes.dart';

class ShapeIcon extends StatelessWidget {
  final String shape;
  final double size;
  final Color color;
  final double strokeWidth;

  const ShapeIcon({
    super.key,
    required this.shape,
    this.size = 48,
    this.color = Colors.white,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapeIconPainter(
          shape: shape,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _ShapeIconPainter extends CustomPainter {
  final String shape;
  final Color color;
  final double strokeWidth;

  _ShapeIconPainter({
    required this.shape,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final iconSize = min(size.width, size.height) - strokeWidth * 2;

    final shapeDef = ShapeRegistry.get(shape);
    if (shapeDef != null) {
      final path = shapeDef.toFlutterPath(center, iconSize);
      canvas.drawPath(path, paint);
    } else {
      // Unknown shape - draw question mark placeholder
      final radius = iconSize / 2;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(color: color, fontSize: radius),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeIconPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
