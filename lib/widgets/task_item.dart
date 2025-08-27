import 'package:flutter/material.dart';
import '../models/enhanced_task.dart';
import '../core/constants/colors.dart';

class TaskItem extends StatelessWidget {
  final EnhancedTask task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final isVeryCompact = screenWidth < 360;
    
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isVeryCompact ? 2 : 4,
        horizontal: isVeryCompact ? 4 : 0,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isVeryCompact ? 8 : 16,
          vertical: isVeryCompact ? 4 : 8,
        ),
        leading: CircleAvatar(
          radius: isVeryCompact ? 16 : 20,
          backgroundColor: _getPriorityColor(task.priority),
          child: Text(
            task.title.isNotEmpty ? task.title[0].toUpperCase() : 'T',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isVeryCompact ? 12 : 14,
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
            fontSize: isVeryCompact ? 14 : 16,
          ),
          maxLines: isVeryCompact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty && !isVeryCompact) ...[
              Text(
                task.description,
                style: TextStyle(
                  color: task.isCompleted ? Colors.grey : null,
                  fontSize: isCompact ? 12 : 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isCompact ? 2 : 4),
            ],
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${task.completedPomodoros}/${task.estimatedPomodoros} pomodoros',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isVeryCompact 
          ? PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                if (!task.isCompleted)
                  PopupMenuItem(
                    onTap: onComplete,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Text('Complete', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!task.isCompleted) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: onComplete,
                    color: AppColors.success,
                    iconSize: isCompact ? 20 : 24,
                    padding: EdgeInsets.all(isCompact ? 8 : 12),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: AppColors.error,
                  iconSize: isCompact ? 20 : 24,
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                ),
              ],
            ),
        onTap: onTap,
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.deepPurple;
    }
  }
}
