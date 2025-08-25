import 'package:flutter/material.dart';
import 'dart:math' as math;

class EfficiencyWidget extends StatelessWidget {
  final double efficiency;

  const EfficiencyWidget({super.key, required this.efficiency});

  @override
  Widget build(BuildContext context) {
    final efficiencyColor = _getEfficiencyColor(efficiency);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: efficiencyColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Efficiency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: EfficiencyCirclePainter(
                      efficiency: efficiency,
                      color: efficiencyColor,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${efficiency.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: efficiencyColor,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getEfficiencyMessage(efficiency),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 80) return Colors.green;
    if (efficiency >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getEfficiencyMessage(double efficiency) {
    if (efficiency >= 90) return 'Excellent focus!';
    if (efficiency >= 80) return 'Great consistency!';
    if (efficiency >= 70) return 'Good progress!';
    if (efficiency >= 60) return 'Keep improving!';
    return 'Room for growth';
  }
}

class EfficiencyCirclePainter extends CustomPainter {
  final double efficiency;
  final Color color;

  EfficiencyCirclePainter({required this.efficiency, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (efficiency / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is EfficiencyCirclePainter &&
        (oldDelegate.efficiency != efficiency || oldDelegate.color != color);
  }
}