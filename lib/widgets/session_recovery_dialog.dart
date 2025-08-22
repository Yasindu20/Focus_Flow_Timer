import 'package:flutter/material.dart';
import '../models/timer_session.dart';
import '../services/advanced_timer_service.dart'; // Added import for TimerType

class SessionRecoveryDialog extends StatelessWidget {
  final TimerSession session;
  final VoidCallback onRecover;
  final VoidCallback onDiscard;

  const SessionRecoveryDialog({
    super.key, // Fixed: Using super parameter
    required this.session,
    required this.onRecover,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(session.startTime);
    final plannedDuration = Duration(milliseconds: session.plannedDuration);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        // Fixed: Added const
        children: [
          Icon(
            Icons.restore,
            color: Colors.orange,
            size: 28,
          ),
          SizedBox(width: 12),
          Text('Recover Session'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found an unfinished timer session that was interrupted.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(
                  alpha: 0.1), // Fixed: Using withValues instead of withOpacity
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSessionDetail(
                  'Session Type',
                  _getSessionTypeName(session.type),
                  Icons.timer,
                ),
                const SizedBox(height: 8),
                _buildSessionDetail(
                  'Planned Duration',
                  _formatDuration(plannedDuration),
                  Icons.schedule,
                ),
                const SizedBox(height: 8),
                _buildSessionDetail(
                  'Time Since Start',
                  _formatDuration(elapsed),
                  Icons.access_time,
                ),
                if (session.taskId != null) ...[
                  const SizedBox(height: 8),
                  _buildSessionDetail(
                    'Associated Task',
                    'Task ${session.taskId}',
                    Icons.task,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Would you like to resume this session or start fresh?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDiscard,
          child: Text(
            'Start Fresh',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onRecover,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Fixed: Added return statement for all cases
  String _getSessionTypeName(TimerType type) {
    switch (type) {
      case TimerType.work:
        return 'Focus Session';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
      case TimerType.custom:
        return 'Custom Session';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
