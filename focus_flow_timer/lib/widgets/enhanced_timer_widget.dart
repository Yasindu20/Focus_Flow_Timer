import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/advanced_timer_service.dart';
import '../core/constants/colors.dart';
import 'precision_circular_progress.dart';
import 'timer_controls.dart';
import 'session_recovery_dialog.dart';

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
        // Show recovery dialog if needed
        if (timerProvider.showRecoveryDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRecoveryDialog(context, timerProvider);
          });
        }

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

            // Precision and performance info
            _buildPerformanceInfo(timerProvider),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getSessionColor(provider.currentType),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getSessionColor(provider.currentType).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSessionIcon(provider.currentType),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                _getSessionText(provider.currentType),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (provider.sessionCount > 0)
                Text(
                  'Session ${provider.sessionCount + 1}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          _buildStateIndicator(provider.state),
        ],
      ),
    );
  }

  Widget _buildStateIndicator(TimerState state) {
    Color color;
    IconData icon;

    switch (state) {
      case TimerState.idle:
        color = Colors.white60;
        icon = Icons.timer_outlined;
        break;
      case TimerState.running:
        color = Colors.green;
        icon = Icons.play_arrow;
        break;
      case TimerState.paused:
        color = Colors.orange;
        icon = Icons.pause;
        break;
      case TimerState.completed:
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case TimerState.interrupted:
        color = Colors.red;
        icon = Icons.warning;
        break;
      case TimerState.recovering:
        color = Colors.purple;
        icon = Icons.restore;
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
          child: SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),

                // Progress indicator
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: PrecisionCircularProgress(
                    progress: 1.0 - provider.progress,
                    color: _getSessionColor(provider.currentType),
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 12,
                    precision: provider.timerService.precision,
                  ),
                ),

                // Timer content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main time display
                    Text(
                      provider.formattedTime,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getSessionColor(provider.currentType),
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Session info
                    Text(
                      'Session ${provider.sessionCount + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),

                    const SizedBox(height: 4),

                    // Precision indicator
                    if (provider.timerService.precision !=
                        TimerPrecision.second)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getSessionColor(provider.currentType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPrecisionText(provider.timerService.precision),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSessionColor(provider.currentType),
                          ),
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

  Widget _buildPerformanceInfo(EnhancedTimerProvider provider) {
    if (!provider.isInitialized || provider.performanceMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Accuracy',
            '${(provider.performanceMetrics['accuracy'] ?? 0.0).toStringAsFixed(1)}%',
            Icons.precision_manufacturing,
          ),
          _buildMetricItem(
            'Sessions',
            '${provider.sessionCount}',
            Icons.timer,
          ),
          _buildMetricItem(
            'Focus Time',
            _formatDuration(provider.performanceMetrics['totalFocusTime'] ?? 0),
            Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
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

  void _showRecoveryDialog(
      BuildContext context, EnhancedTimerProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionRecoveryDialog(
        session: provider.recoverySession!,
        onRecover: () => provider.handleRecovery(true),
        onDiscard: () => provider.handleRecovery(false),
      ),
    );
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
      case TimerType.work:
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
      case TimerType.work:
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
      case TimerType.work:
        return 'Focus Time';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
      case TimerType.custom:
        return 'Custom Session';
    }
  }

  String _getPrecisionText(TimerPrecision precision) {
    switch (precision) {
      case TimerPrecision.second:
        return 'SEC';
      case TimerPrecision.decisecond:
        return 'DSEC';
      case TimerPrecision.centisecond:
        return 'CSEC';
      case TimerPrecision.millisecond:
        return 'MSEC';
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
