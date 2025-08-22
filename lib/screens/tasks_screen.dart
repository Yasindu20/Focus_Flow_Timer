import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_task_provider.dart';
import '../widgets/task_item.dart';
import '../models/enhanced_task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Active tasks
              _buildTaskList(
                tasks: taskProvider.incompleteTasks,
                emptyMessage: 'No active tasks. Add your first task!',
              ),

              // Completed tasks
              _buildTaskList(
                tasks: taskProvider.completedTasks,
                emptyMessage: 'No completed tasks yet.',
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList({
    required List<Task> tasks,
    required String emptyMessage,
  }) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return TaskItem(
          task: task,
          onTap: () => _showTaskDetailsDialog(context, task),
          onComplete: () => _completeTask(context, task),
          onDelete: () => _deleteTask(context, task),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddTaskDialog());
  }

  void _showTaskDetailsDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );
  }

  void _completeTask(BuildContext context, Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.completeTask(task.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" completed!'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality if needed
          },
        ),
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final taskProvider = Provider.of<TaskProvider>(
                context,
                listen: false,
              );
              taskProvider.deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _estimatedPomodoros = 1;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Estimated Pomodoros:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _estimatedPomodoros,
                  items: List.generate(10, (index) => index + 1)
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _estimatedPomodoros = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Priority:'),
                const SizedBox(width: 16),
                DropdownButton<TaskPriority>(
                  value: _priority,
                  items: TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _priority = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addTask, child: const Text('Add Task')),
      ],
    );
  }

  void _addTask() {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.addTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      estimatedPomodoros: _estimatedPomodoros,
      priority: _priority,
    );

    Navigator.pop(context);
  }
}

class TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(task.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description.isNotEmpty) ...[
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(task.description),
            const SizedBox(height: 12),
          ],
          const Text(
            'Progress:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${task.completedPomodoros}/${task.estimatedPomodoros} pomodoros',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: task.estimatedPomodoros > 0
                ? task.completedPomodoros / task.estimatedPomodoros
                : 0.0,
          ),
          const SizedBox(height: 12),
          const Text(
            'Priority:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(task.priority.name.toUpperCase()),
          const SizedBox(height: 12),
          const Text('Created:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(task.createdAt.toString().substring(0, 16)),
          if (task.completedAt != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Completed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(task.completedAt.toString().substring(0, 16)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
