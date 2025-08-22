import 'package:flutter/material.dart';
import 'dart:math';
import '../services/advanced_timer_service.dart';

class PrecisionCircularProgress extends StatefulWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final TimerPrecision precision;
  final bool showMilliseconds;

  const PrecisionCircularProgress({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = Colors.grey,
    this.strokeWidth = 8.0,
    this.precision = TimerPrecision.centisecond,
    this.showMilliseconds = false,
  });

  @override
  State<PrecisionCircularProgress> createState() =>
      _PrecisionCircularProgressState();
}

class _PrecisionCircularProgressState extends State<PrecisionCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60 FPS for smooth animation
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void didUpdateWidget(PrecisionCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animateToProgress();
    }
  }

  void _animateToProgress() {
    final duration = _getAnimationDuration();
    _animationController.duration = duration;
    _animationController.forward();
  }

  Duration _getAnimationDuration() {
    switch (widget.precision) {
      case TimerPrecision.second:
        return const Duration(milliseconds: 100);
      case TimerPrecision.decisecond:
        return const Duration(milliseconds: 50);
      case TimerPrecision.centisecond:
        return const Duration(milliseconds: 16); // 60 FPS
      case TimerPrecision.millisecond:
        return const Duration(milliseconds: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: PrecisionCircularProgressPainter(
            progress: widget.progress,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
            strokeWidth: widget.strokeWidth,
            precision: widget.precision,
            animationValue: _animation.value,
          ),
          child: Container(),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class PrecisionCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final TimerPrecision precision;
  final double animationValue;

  PrecisionCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.precision,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = _createProgressShader(center, radius)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Draw precision segments for high-precision modes
    if (precision == TimerPrecision.centisecond ||
        precision == TimerPrecision.millisecond) {
      _drawPrecisionSegments(
          canvas, center, radius, progressPaint, startAngle, sweepAngle);
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Draw precision indicators
    _drawPrecisionMarkers(canvas, center, radius);
  }

  void _drawPrecisionSegments(Canvas canvas, Offset center, double radius,
      Paint paint, double startAngle, double sweepAngle) {
    final segments = _getPrecisionSegments();
    final segmentAngle = sweepAngle / segments;

    for (int i = 0; i < segments; i++) {
      final segmentStart = startAngle + (i * segmentAngle);
      final alpha = (1.0 - (i / segments)) * animationValue;

      final segmentPaint = Paint()
        ..color = color.withOpacity(alpha)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segmentStart,
        segmentAngle * 0.8, // Small gap between segments
        false,
        segmentPaint,
      );
    }
  }

  void _drawPrecisionMarkers(Canvas canvas, Offset center, double radius) {
    if (precision == TimerPrecision.second) return;

    final markerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final markers = _getPrecisionMarkers();
    for (int i = 0; i < markers; i++) {
      final angle = (2 * pi * i) / markers - pi / 2;
      final startPoint = Offset(
        center.dx + (radius - strokeWidth / 2) * cos(angle),
        center.dy + (radius - strokeWidth / 2) * sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius + strokeWidth / 2) * cos(angle),
        center.dy + (radius + strokeWidth / 2) * sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, markerPaint);
    }
  }

  Shader _createProgressShader(Offset center, double radius) {
    return LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color,
        color.withOpacity(0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  int _getPrecisionSegments() {
    switch (precision) {
      case TimerPrecision.second:
        return 60;
      case TimerPrecision.decisecond:
        return 100;
      case TimerPrecision.centisecond:
        return 200;
      case TimerPrecision.millisecond:
        return 1000;
    }
  }

  int _getPrecisionMarkers() {
    switch (precision) {
      case TimerPrecision.second:
        return 0;
      case TimerPrecision.decisecond:
        return 10;
      case TimerPrecision.centisecond:
        return 20;
      case TimerPrecision.millisecond:
        return 100;
    }
  }

  @override
  bool shouldRepaint(covariant PrecisionCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.precision != precision;
  }
}
