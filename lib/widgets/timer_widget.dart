import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../services/timer_service.dart';
import '../core/constants/colors.dart';
import 'circular_progress.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final timerService = timerProvider.timerService;

        return Column(
          children: [
            // Session type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getSessionColor(timerService.currentType),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getSessionText(timerService.currentType),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Circular timer
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgress(
                progress: 1.0 - timerService.progress,
                color: _getSessionColor(timerService.currentType),
                backgroundColor: Colors.grey,
                strokeWidth: 12,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timerService.formattedTime,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Session ${timerService.sessionCount + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reset button
                FloatingActionButton(
                  onPressed: timerProvider.resetTimer,
                  backgroundColor: Colors.grey[600],
                  child: const Icon(Icons.refresh),
                ),

                // Main play/pause button
                FloatingActionButton.extended(
                  onPressed: () {
                    switch (timerService.state) {
                      case TimerState.stopped:
                        timerProvider.startTimer();
                        break;
                      case TimerState.running:
                        timerProvider.pauseTimer();
                        break;
                      case TimerState.paused:
                        timerProvider.resumeTimer();
                        break;
                    }
                  },
                  backgroundColor: _getSessionColor(timerService.currentType),
                  icon: Icon(_getPlayPauseIcon(timerService.state)),
                  label: Text(_getPlayPauseText(timerService.state)),
                ),

                // Skip button
                FloatingActionButton(
                  onPressed: timerProvider.skipSession,
                  backgroundColor: Colors.orange[600],
                  child: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Color _getSessionColor(TimerType type) {
    switch (type) {
      case TimerType.work:
        return AppColors.workColor;
      case TimerType.shortBreak:
      case TimerType.longBreak:
        return AppColors.breakColor;
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
    }
  }

  IconData _getPlayPauseIcon(TimerState state) {
    switch (state) {
      case TimerState.stopped:
      case TimerState.paused:
        return Icons.play_arrow;
      case TimerState.running:
        return Icons.pause;
    }
  }

  String _getPlayPauseText(TimerState state) {
    switch (state) {
      case TimerState.stopped:
        return 'Start';
      case TimerState.paused:
        return 'Resume';
      case TimerState.running:
        return 'Pause';
    }
  }
}
