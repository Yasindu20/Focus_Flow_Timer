import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/enhanced_timer_widget.dart';
import '../widgets/sound_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Fixed: Using super parameter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Flow',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        'Stay focused, get things done',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Current task selection
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final incompleteTasks = taskProvider.incompleteTasks;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Task',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          if (incompleteTasks.isEmpty) ...[
                            Text(
                              'No tasks available. Add a task to get started!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/tasks'),
                              child: const Text('Add Task'),
                            ),
                          ] else ...[
                            Consumer<EnhancedTimerProvider>(
                              builder: (context, timerProvider, child) {
                                final currentTaskId =
                                    timerProvider.currentTaskId;
                                final currentTask = currentTaskId != null
                                    ? taskProvider.getTaskById(currentTaskId)
                                    : null;

                                return DropdownButtonFormField<String>(
                                  value: currentTaskId,
                                  decoration: const InputDecoration(
                                    hintText: 'Select a task to focus on',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('No specific task'),
                                    ),
                                    ...incompleteTasks.map((task) {
                                      return DropdownMenuItem(
                                        value: task.id,
                                        child: Text(task.title),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (taskId) {
                                    timerProvider.setCurrentTask(taskId);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/tasks'),
                              child: const Text('Manage Tasks'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Timer widget
              const EnhancedTimerWidget(),

              const SizedBox(height: 32),

              // Sound selector
              const SoundSelector(),
            ],
          ),
        ),
      ),
    );
  }
}
