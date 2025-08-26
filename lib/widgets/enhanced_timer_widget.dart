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
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 340,
            height: 340,
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
                // Primary shadow for depth
                BoxShadow(
                  color: AppColors.timerShadow,
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
                // Secondary shadow for softer glow
                BoxShadow(
                  color: _getSessionColor(provider.currentType).withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress track (background)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                ),

                // Main progress indicator - CLOCKWISE
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: -1.5708, // -π/2 radians (start from top)
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: CircularProgressIndicator(
                        value: provider.progress, // Changed from 1.0 - provider.progress
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getSessionColor(provider.currentType),
                        ),
                      ),
                    ),
                  ),
                ),

                // Timer content with enhanced design
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress percentage indicator with accessibility
                    Semantics(
                      label: 'Progress: ${(provider.progress * 100).toInt()} percent complete',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSessionColor(provider.currentType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(provider.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getSessionColor(provider.currentType),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Main time display with accessibility
                    Semantics(
                      label: 'Timer: ${provider.formattedTime.replaceAll(':', ' minutes, ')} seconds remaining',
                      hint: 'Current ${_getSessionText(provider.currentType).toLowerCase()} session time',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          provider.formattedTime,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 52,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                            fontFeatures: [const FontFeature.tabularFigures()],
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Session info with icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSessionIcon(provider.currentType),
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Session ${provider.sessionCount + 1}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressTrack),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Rounds',
            '${provider.sessionCount + 1}',
            Icons.refresh,
            _getSessionColor(provider.currentType),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.progressTrack,
          ),
          _buildMetricItem(
            'Mode',
            _getShortSessionText(provider.currentType),
            _getSessionIcon(provider.currentType),
            AppColors.textSecondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.progressTrack,
          ),
          _buildMetricItem(
            'Status',
            _getStateText(provider.state),
            _getStateIcon(provider.state),
            _getStateColor(provider.state),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
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
