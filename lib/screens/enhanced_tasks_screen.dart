import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/enhanced_task_card.dart';
import '../widgets/quick_add_task_modal.dart';
import '../models/task.dart';
import '../models/enhanced_task.dart';
import 'tasks_screen.dart'; // Import for TaskDetailsDialog

/// Modern, mobile-first task management screen with rich interactions
class EnhancedTasksScreen extends StatefulWidget {
  const EnhancedTasksScreen({super.key});

  @override
  State<EnhancedTasksScreen> createState() => _EnhancedTasksScreenState();
}

class _EnhancedTasksScreenState extends State<EnhancedTasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;
  late AnimationController _filterController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _filterAnimation;

  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showFilters = false;
  TaskPriority? _filterPriority;
  TaskCategory? _filterCategory;
  final Set<String> _selectedTaskIds = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    ));

    _filterAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutCubic,
    ));

    _fabController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    _filterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabBar(isDark),
              if (_showFilters) _buildFilterBar(isDark),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSmartFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  BoxDecoration _buildBackgroundDecoration(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF0D1117),
                const Color(0xFF161B22),
                const Color(0xFF21262D),
              ]
            : [
                const Color(0xFFFAFBFC),
                const Color(0xFFF6F8FA),
                const Color(0xFFEBEDF0),
              ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              if (_isMultiSelectMode) ...[
                _buildSelectAllButton(isDark),
                const SizedBox(width: 12),
                _buildBulkActionsButton(isDark),
                const Spacer(),
                _buildExitMultiSelectButton(isDark),
              ] else ...[
                _buildHeaderTitle(isDark),
                const Spacer(),
                _buildHeaderActions(isDark),
              ],
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 16),
            _buildSearchBar(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Consumer<TaskProvider>(
          builder: (context, taskProvider, _) {
            final activeCount = taskProvider.incompleteTasks.length;
            final completedToday = taskProvider.completedTasks
                .where((t) => _isToday(t.completedAt))
                .length;
            
            return Text(
              '$activeCount active • $completedToday completed today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderActions(bool isDark) {
    return Row(
      children: [
        _buildHeaderActionButton(
          icon: Icons.search_rounded,
          onTap: () => setState(() => _isSearching = !_isSearching),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildHeaderActionButton(
          icon: _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          onTap: _toggleFilters,
          isDark: isDark,
          isActive: _showFilters,
        ),
        const SizedBox(width: 8),
        _buildHeaderActionButton(
          icon: Icons.more_vert_rounded,
          onTap: () => _showMoreOptions(context),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            onTap();
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(12),
          child: Icon(
            icon,
            color: isActive 
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.white : Colors.black87),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectAllButton(bool isDark) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final tasks = _getCurrentTasks(taskProvider);
        final allSelected = tasks.isNotEmpty && 
            tasks.every((t) => _selectedTaskIds.contains(t.id));
        
        return GestureDetector(
          onTap: () => _toggleSelectAll(tasks),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: allSelected 
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActionsButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showBulkActions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.batch_prediction_rounded,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              'Actions (${_selectedTaskIds.length})',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitMultiSelectButton(bool isDark) {
    return GestureDetector(
      onTap: _exitMultiSelectMode,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Colors.red,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return SlideTransition(
      position: _filterAnimation,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Priority',
                      value: _filterPriority?.name.toUpperCase(),
                      onTap: () => _showPriorityFilter(context),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Category',
                      value: _filterCategory?.name.toLowerCase(),
                      onTap: () => _showCategoryFilter(context),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Due Today',
                      onTap: () {
                setState(() {
                  // TODO: Implement due today filter logic
                });
              },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isActive = value != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: isActive 
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.clear_rounded,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ] else
              const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive 
                  ? Theme.of(context).primaryColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTaskList(TaskListType.active),
        _buildTaskList(TaskListType.completed),
        _buildTaskList(TaskListType.all),
      ],
    );
  }

  Widget _buildTaskList(TaskListType type) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final tasks = _getFilteredTasks(taskProvider, type);
        
        if (tasks.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger refresh of tasks from provider
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_isMultiSelectMode)
                SliverToBoxAdapter(
                  child: _buildMultiSelectHeader(tasks.length),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(task, taskProvider);
                  },
                  childCount: tasks.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Space for FAB
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(EnhancedTask task, TaskProvider taskProvider) {
    return EnhancedTaskCard(
      task: task,
      isSelected: _selectedTaskIds.contains(task.id),
      onTap: _isMultiSelectMode 
          ? () => _toggleTaskSelection(task.id)
          : () => _showTaskDetails(task),
      onComplete: () => _completeTask(taskProvider, task),
      onDelete: () => _deleteTask(taskProvider, task),
      onEdit: () => _editTask(task),
      onStartPomodoro: () => _startPomodoro(task),
    );
  }

  Widget _buildEmptyState(TaskListType type) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (type) {
      case TaskListType.active:
        title = 'No active tasks';
        subtitle = 'Create your first task to get started!';
        icon = Icons.task_alt_rounded;
        color = Colors.blue;
        break;
      case TaskListType.completed:
        title = 'No completed tasks';
        subtitle = 'Completed tasks will appear here';
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case TaskListType.all:
        title = 'No tasks found';
        subtitle = 'Try adjusting your search or filters';
        icon = Icons.search_rounded;
        color = Colors.orange;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (type == TaskListType.active) ...[
              const SizedBox(height: 32),
              _buildCreateTaskButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTaskButton() {
    return ElevatedButton.icon(
      onPressed: () => _showQuickAddTask(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Task'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMultiSelectHeader(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            '${_selectedTaskIds.length} of $totalCount selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFAB() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: _isMultiSelectMode
              ? _buildMultiSelectFAB()
              : _buildNormalFAB(),
        );
      },
    );
  }

  Widget _buildNormalFAB() {
    return FloatingActionButton.extended(
      heroTag: "enhanced_tasks_fab",
      onPressed: () => _showQuickAddTask(context),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Task',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMultiSelectFAB() {
    return FloatingActionButton.extended(
      heroTag: "multi_select_fab",
      onPressed: () => _showBulkActions(context),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.batch_prediction_rounded),
      label: Text(
        'Actions (${_selectedTaskIds.length})',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  // Helper methods and event handlers
  List<EnhancedTask> _getCurrentTasks(TaskProvider taskProvider) {
    switch (_tabController.index) {
      case 0:
        return taskProvider.incompleteTasks.map((t) => t.toEnhancedTask()).toList();
      case 1:
        return taskProvider.completedTasks.map((t) => t.toEnhancedTask()).toList();
      case 2:
      default:
        return [
          ...taskProvider.incompleteTasks.map((t) => t.toEnhancedTask()),
          ...taskProvider.completedTasks.map((t) => t.toEnhancedTask()),
        ];
    }
  }

  List<EnhancedTask> _getFilteredTasks(TaskProvider taskProvider, TaskListType type) {
    List<EnhancedTask> tasks;
    
    switch (type) {
      case TaskListType.active:
        tasks = taskProvider.incompleteTasks.map((t) => t.toEnhancedTask()).toList();
        break;
      case TaskListType.completed:
        tasks = taskProvider.completedTasks.map((t) => t.toEnhancedTask()).toList();
        break;
      case TaskListType.all:
        tasks = [
          ...taskProvider.incompleteTasks.map((t) => t.toEnhancedTask()),
          ...taskProvider.completedTasks.map((t) => t.toEnhancedTask()),
        ];
        break;
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tasks = tasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
               task.description.toLowerCase().contains(query) ||
               task.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply priority filter
    if (_filterPriority != null) {
      tasks = tasks.where((task) => task.priority == _filterPriority).toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      tasks = tasks.where((task) => task.category == _filterCategory).toList();
    }

    // Sort tasks
    tasks.sort((a, b) {
      // First by completion status
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // Then by urgency
      final urgencyOrder = {
        TaskUrgency.critical: 0,
        TaskUrgency.high: 1,
        TaskUrgency.medium: 2,
        TaskUrgency.low: 3,
      };
      
      final aUrgency = urgencyOrder[a.urgency] ?? 3;
      final bUrgency = urgencyOrder[b.urgency] ?? 3;
      
      if (aUrgency != bUrgency) {
        return aUrgency.compareTo(bUrgency);
      }
      
      // Finally by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return tasks;
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterController.forward();
    } else {
      _filterController.reverse();
    }
  }

  void _clearFilters() {
    setState(() {
      _filterPriority = null;
      _filterCategory = null;
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
      
      if (_selectedTaskIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
    
    HapticFeedback.selectionClick();
  }

  void _toggleSelectAll(List<EnhancedTask> tasks) {
    final taskIds = tasks.map((t) => t.id).toSet();
    final allSelected = taskIds.every((id) => _selectedTaskIds.contains(id));
    
    setState(() {
      if (allSelected) {
        _selectedTaskIds.removeAll(taskIds);
        if (_selectedTaskIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTaskIds.addAll(taskIds);
        _isMultiSelectMode = true;
      }
    });
    
    HapticFeedback.selectionClick();
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedTaskIds.clear();
    });
  }

  // Task actions
  void _completeTask(TaskProvider taskProvider, EnhancedTask task) {
    final legacyTask = Task.fromEnhancedTask(task);
    taskProvider.completeTask(legacyTask.id);
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task.title}" completed!'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Re-mark task as incomplete
            taskProvider.completeTask(legacyTask.id); // This should toggle
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _deleteTask(TaskProvider taskProvider, EnhancedTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final legacyTask = Task.fromEnhancedTask(task);
              taskProvider.deleteTask(legacyTask.id);
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTask(EnhancedTask task) {
    // For now, use the existing AddTaskDialog - in a full implementation this would be an EditTaskDialog
    showDialog(
      context: context, 
      builder: (context) => const AddTaskDialog()
    );
  }

  void _startPomodoro(EnhancedTask task) {
    // Navigate to timer screen with this task
    HapticFeedback.mediumImpact();
    
    // For now, just show the snackbar - the actual navigation would depend on your app structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting Pomodoro for "${task.title}"'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Go to Timer',
          onPressed: () {
            // Navigator.push(context, MaterialPageRoute(builder: (_) => TimerScreen(task: task)));
          },
        ),
      ),
    );
  }

  void _showTaskDetails(EnhancedTask task) {
    // Use existing TaskDetailsDialog from original tasks_screen.dart
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(task: Task.fromEnhancedTask(task)),
    );
  }

  void _showQuickAddTask(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const QuickAddTaskModal(),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort Tasks'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Task Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkActions(BuildContext context) {
    if (_selectedTaskIds.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text('Complete ${_selectedTaskIds.length} tasks'),
              onTap: () {
                Navigator.pop(context);
                // Implement bulk complete
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete ${_selectedTaskIds.length} tasks'),
              onTap: () {
                Navigator.pop(context);
                // Implement bulk delete
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskPriority.values.map((priority) => 
            RadioListTile<TaskPriority?>(
              title: Text(priority.name.toUpperCase()),
              value: priority,
              groupValue: _filterPriority,
              onChanged: (value) {
                setState(() => _filterPriority = value);
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskCategory.values.map((category) => 
            RadioListTile<TaskCategory?>(
              title: Text(category.name.toLowerCase()),
              value: category,
              groupValue: _filterCategory,
              onChanged: (value) {
                setState(() => _filterCategory = value);
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}

enum TaskListType { active, completed, all }