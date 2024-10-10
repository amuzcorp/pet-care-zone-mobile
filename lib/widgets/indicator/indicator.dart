import 'package:flutter/material.dart';
import 'dart:math';

class GradientCircularLoader extends StatefulWidget {
  final double? size;
  final Duration duration;

  const GradientCircularLoader({super.key,
    this.size,
    this.duration = const Duration(seconds: 1),
  });

  @override
  _GradientCircularLoaderState createState() => _GradientCircularLoaderState();
}

class _GradientCircularLoaderState extends State<GradientCircularLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size(widget.size ?? 50.0, widget.size ?? 50.0),
        painter: _GradientCircularLoaderPainter(),
      ),
    );
  }
}

class _GradientCircularLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    const gradient = SweepGradient(
      colors: [
        Color(0xFF098BEA),
        Color(0xFF96FFB6),
        Color(0xFF08D3C5),
        Color(0xFF098BEA),
      ],
      stops: [0.0, 0.5, 0.8, 1.0],
      startAngle: 0.0,
      endAngle: 2 * pi,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);

    final strokeWidth = size.width / 10;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      1.7 * pi * 0.85,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
