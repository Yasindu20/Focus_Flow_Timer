import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/enhanced_timer_widget.dart';
import '../widgets/sound_selector.dart';
import '../widgets/timer_config_panel.dart';
import '../core/constants/colors.dart';
import '../core/utils/responsive_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Fixed: Using super parameter

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? (ResponsiveUtils.isSmallMobile(context) ? 8 : 12) : 16,
                  vertical: isSmallScreen ? 6 : 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Enhanced Header
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Focus Flow',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Stay focused, achieve more',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 32),

              // Enhanced task selection
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final incompleteTasks = taskProvider.incompleteTasks;

                  return Container(
                    padding: EdgeInsets.all(isMobile ? (ResponsiveUtils.isSmallMobile(context) ? 12 : 16) : 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
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
                              Icons.task_alt_rounded,
                              size: 20,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: isMobile ? (ResponsiveUtils.isSmallMobile(context) ? 4 : 6) : 8),
                            Text(
                              'Current Focus',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (incompleteTasks.isEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 32,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add your first task to get started',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/tasks'),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Task'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Consumer<EnhancedTimerProvider>(
                            builder: (context, timerProvider, child) {
                              final currentTaskId = timerProvider.currentTaskId;

                              return Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? (ResponsiveUtils.isSmallMobile(context) ? 8 : 12) : 16, 
                                      vertical: 4
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.progressTrack),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentTaskId,
                                        hint: Text(
                                          'Choose your focus task',
                                          style: TextStyle(color: AppColors.textTertiary),
                                        ),
                                        isExpanded: true,
                                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                        items: [
                                          const DropdownMenuItem(
                                            value: null,
                                            child: Text('General focus session'),
                                          ),
                                          ...incompleteTasks.map((task) {
                                            return DropdownMenuItem(
                                              value: task.id,
                                              child: Text(task.title),
                                            );
                                          }),
                                        ],
                                        onChanged: (taskId) {
                                          timerProvider.setCurrentTask(taskId);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: TextButton.icon(
                                              onPressed: () => Navigator.pushNamed(context, '/tasks'),
                                              icon: Icon(Icons.edit_rounded, size: 16),
                                              label: const Text('Manage Tasks'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.primaryBlue,
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Timer configuration panel
              const TimerConfigPanel(),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Timer widget
              const EnhancedTimerWidget(),

              SizedBox(height: isSmallScreen ? 16 : 24),

              // Sound selector
              const SoundSelector(),
              
              // Add bottom padding for mobile
              SizedBox(height: isMobile ? 20 : 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
