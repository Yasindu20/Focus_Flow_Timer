import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../core/enums/timer_enums.dart';
import '../core/constants/colors.dart';
import 'timer_controls.dart';

class EnhancedTimerWidget extends StatefulWidget {
  const EnhancedTimerWidget({super.key});

  @override
  State<EnhancedTimerWidget> createState() => _EnhancedTimerWidgetState();
}

class _EnhancedTimerWidgetState extends State<EnhancedTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        // Control animations based on timer state
        _handleTimerStateAnimations(timerProvider.state);

        return Column(
          children: [
            // Session type and status
            _buildSessionHeader(timerProvider),

            const SizedBox(height: 32),

            // Main timer display
            _buildTimerDisplay(timerProvider),

            const SizedBox(height: 48),

            // Timer controls
            TimerControls(
              onStart: () => _handleStart(timerProvider),
              onPause: () => _handlePause(timerProvider),
              onResume: () => _handleResume(timerProvider),
              onStop: () => _handleStop(timerProvider),
              onSkip: () => _handleSkip(timerProvider),
              state: timerProvider.state,
            ),

            const SizedBox(height: 24),

            // Session info
            _buildSessionInfo(timerProvider),

            // Error display
            if (timerProvider.lastError != null)
              _buildErrorDisplay(timerProvider.lastError!),
          ],
        );
      },
    );
  }

  Widget _buildSessionHeader(EnhancedTimerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getSessionColor(provider.currentType),
            _getSessionColor(provider.currentType).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getSessionColor(provider.currentType).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getSessionIcon(provider.currentType),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSessionText(provider.currentType),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              if (provider.sessionCount >= 0)
                Text(
                  'Round ${provider.sessionCount + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          _buildStateIndicator(provider.state),
        ],
      ),
    );
  }

  Widget _buildStateIndicator(TimerState state) {
    Color color;

    switch (state) {
      case TimerState.idle:
        color = Colors.white60;
        break;
      case TimerState.running:
        color = Colors.green;
        break;
      case TimerState.paused:
        color = Colors.orange;
        break;
      case TimerState.completed:
        color = Colors.blue;
        break;
      case TimerState.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTimerDisplay(EnhancedTimerProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final timerSize = isMobile ? (screenWidth * 0.8).clamp(280.0, 320.0) : 340.0;
    final progressSize = timerSize - 40;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: timerSize,
            height: timerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
                stops: const [0.0, 1.0],
              ),
              boxShadow: [
                // Primary shadow for depth - reduced on mobile
                BoxShadow(
                  color: AppColors.timerShadow,
                  blurRadius: isMobile ? 20 : 30,
                  offset: Offset(0, isMobile ? 10 : 15),
                  spreadRadius: isMobile ? -3 : -5,
                ),
                // Secondary shadow for softer glow
                BoxShadow(
                  color: _getSessionColor(provider.currentType).withValues(alpha: 0.1),
                  blurRadius: isMobile ? 25 : 40,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom circular progress that starts from top
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CustomPaint(
                      painter: CircularProgressPainter(
                        progress: provider.progress,
                        progressColor: _getSessionColor(provider.currentType),
                        backgroundColor: AppColors.progressTrack,
                        strokeWidth: isMobile ? 6.0 : 8.0,
                      ),
                    ),
                  ),
                ),

                // Timer content with enhanced design - responsive
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 8 : 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress percentage indicator with accessibility
                      Semantics(
                        label: 'Progress: ${(provider.progress * 100).toInt()} percent complete',
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12,
                            vertical: isMobile ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSessionColor(provider.currentType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(provider.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              color: _getSessionColor(provider.currentType),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isMobile ? 12 : 16),

                      // Main time display with accessibility - responsive
                      Semantics(
                        label: 'Timer: ${provider.formattedTime.replaceAll(':', ' minutes, ')} seconds remaining',
                        hint: 'Current ${_getSessionText(provider.currentType).toLowerCase()} session time',
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
                            child: Text(
                              provider.formattedTime,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: isMobile ? 42 : 52,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textPrimary,
                                fontFeatures: [const FontFeature.tabularFigures()],
                                letterSpacing: -1.0,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 8 : 12),

                      // Session info with icon - more compact on mobile
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSessionIcon(provider.currentType),
                              size: isMobile ? 12 : 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: isMobile ? 4 : 6),
                            Text(
                              'Session ${provider.sessionCount + 1}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: isMobile ? 10 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionInfo(EnhancedTimerProvider provider) {
    if (!provider.isInitialized) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressTrack),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildMetricItem(
                'Rounds',
                '${provider.sessionCount + 1}',
                Icons.refresh,
                _getSessionColor(provider.currentType),
                isMobile,
              ),
            ),
            Container(
              width: 1,
              color: AppColors.progressTrack,
              margin: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
            ),
            Expanded(
              child: _buildMetricItem(
                'Mode',
                _getShortSessionText(provider.currentType),
                _getSessionIcon(provider.currentType),
                AppColors.textSecondary,
                isMobile,
              ),
            ),
            Container(
              width: 1,
              color: AppColors.progressTrack,
              margin: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
            ),
            Expanded(
              child: _buildMetricItem(
                'Status',
                _getStateText(provider.state),
                _getStateIcon(provider.state),
                _getStateColor(provider.state),
                isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isMobile ? 16 : 18,
          color: color,
        ),
        SizedBox(height: isMobile ? 4 : 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 12 : 14,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: isMobile ? 1 : 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 9 : 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTimerStateAnimations(TimerState state) {
    switch (state) {
      case TimerState.running:
        _pulseController.repeat(reverse: true);
        break;
      case TimerState.paused:
        _pulseController.stop();
        break;
      case TimerState.completed:
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        _pulseController.stop();
        break;
      default:
        _pulseController.stop();
        break;
    }
  }


  void _handleStart(EnhancedTimerProvider provider) {
    provider.startTimer(taskId: provider.currentTaskId);
  }

  void _handlePause(EnhancedTimerProvider provider) {
    provider.pauseTimer();
  }

  void _handleResume(EnhancedTimerProvider provider) {
    provider.resumeTimer();
  }

  void _handleStop(EnhancedTimerProvider provider) {
    provider.stopTimer();
  }

  void _handleSkip(EnhancedTimerProvider provider) {
    provider.skipSession();
  }

  Color _getSessionColor(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return AppColors.workColor;
      case TimerType.shortBreak:
      case TimerType.longBreak:
        return AppColors.breakColor;
      case TimerType.custom:
        return AppColors.primaryBlue;
    }
  }

  IconData _getSessionIcon(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return Icons.work;
      case TimerType.shortBreak:
        return Icons.coffee;
      case TimerType.longBreak:
        return Icons.hotel;
      case TimerType.custom:
        return Icons.timer;
    }
  }

  String _getSessionText(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return 'Focus Time';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
      case TimerType.custom:
        return 'Custom Session';
    }
  }

  String _getStateText(TimerState state) {
    switch (state) {
      case TimerState.idle:
        return 'Ready';
      case TimerState.running:
        return 'Active';
      case TimerState.paused:
        return 'Paused';
      case TimerState.completed:
        return 'Done';
      case TimerState.cancelled:
        return 'Stopped';
    }
  }
  
  String _getShortSessionText(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return 'Focus';
      case TimerType.shortBreak:
        return 'Break';
      case TimerType.longBreak:
        return 'Long Break';
      case TimerType.custom:
        return 'Custom';
    }
  }
  
  IconData _getStateIcon(TimerState state) {
    switch (state) {
      case TimerState.idle:
        return Icons.play_circle_outline;
      case TimerState.running:
        return Icons.play_circle_filled;
      case TimerState.paused:
        return Icons.pause_circle_filled;
      case TimerState.completed:
        return Icons.check_circle;
      case TimerState.cancelled:
        return Icons.stop_circle;
    }
  }
  
  Color _getStateColor(TimerState state) {
    switch (state) {
      case TimerState.idle:
        return AppColors.textTertiary;
      case TimerState.running:
        return AppColors.success;
      case TimerState.paused:
        return AppColors.warning;
      case TimerState.completed:
        return AppColors.success;
      case TimerState.cancelled:
        return AppColors.error;
    }
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

// Custom painter for circular progress that starts from the top
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Paint for background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Paint for progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc starting from top (12 o'clock position)
    if (progress > 0) {
      const startAngle = -math.pi / 2; // Start from top (12 o'clock)
      final sweepAngle = 2 * math.pi * progress; // Clockwise sweep

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.backgroundColor != backgroundColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
