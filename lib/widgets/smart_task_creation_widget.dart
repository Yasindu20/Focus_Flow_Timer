import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_task_provider.dart';
import '../models/enhanced_task.dart';
import '../core/constants/colors.dart';

class SmartTaskCreationWidget extends StatefulWidget {
  final EnhancedTask? editingTask;
  final VoidCallback? onTaskCreated;
  const SmartTaskCreationWidget({
    super.key,
    this.editingTask,
    this.onTaskCreated,
  });
  @override
  State<SmartTaskCreationWidget> createState() =>
      _SmartTaskCreationWidgetState();
}

class _SmartTaskCreationWidgetState extends State<SmartTaskCreationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.general;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _dueDate;
  List<String> _tags = [];
  bool _isAnalyzing = false;
  bool _showAiSuggestions = false;
  // AI Suggestions
  TaskCategory? _aiSuggestedCategory;
  TaskPriority? _aiSuggestedPriority;
  List<String> _aiSuggestedTags = [];
  int? _aiEstimatedMinutes;
  double? _aiConfidence;
  List<String> _aiTips = [];
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextListeners();

    if (widget.editingTask != null) {
      _populateFromTask(widget.editingTask!);
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  void _setupTextListeners() {
    _titleController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_titleController.text.length > 10 && !_isAnalyzing) {
      _triggerAiAnalysis();
    }
  }

  void _populateFromTask(EnhancedTask task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _selectedCategory = task.category;
    _selectedPriority = task.priority;
    _dueDate = task.dueDate;
    _tags = List.from(task.tags);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildForm(),
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildCategoryPriorityRow(),
              const SizedBox(height: 16),
              _buildDueDateField(),
              const SizedBox(height: 16),
              _buildTagsField(),
              if (_showAiSuggestions) ...[
                const SizedBox(height: 24),
                _buildAiSuggestions(),
              ],
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          widget.editingTask != null ? Icons.edit : Icons.add_task,
          color: AppColors.primaryBlue,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editingTask != null ? 'Edit Task' : 'Create New Task',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_isAnalyzing)
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI is analyzing your task...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_aiConfidence != null && _aiConfidence! > 0.7)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 4),
                Text(
                  'AI Confident',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Task Title',
        hintText: 'What needs to be done?',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a task title';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add more details about the task...',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      maxLines: 3,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildCategoryPriorityRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryDropdown(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPriorityDropdown(),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<TaskCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      items: TaskCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 8),
              Text(_getCategoryDisplayName(category)),
              if (_aiSuggestedCategory == category) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<TaskPriority>(
      value: _selectedPriority,
      decoration: InputDecoration(
        labelText: 'Priority',
        prefixIcon: const Icon(Icons.flag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      items: TaskPriority.values.map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Row(
            children: [
              _getPriorityIcon(priority),
              const SizedBox(width: 8),
              Text(_getPriorityDisplayName(priority)),
              if (_aiSuggestedPriority == priority) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPriority = value!;
        });
      },
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      onTap: _selectDueDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date (Optional)',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        child: Text(
          _dueDate != null
              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
              : 'Select due date',
          style: TextStyle(
            color: _dueDate != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.label,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 8),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ..._tags.map((tag) => _buildTagChip(tag, isRemovable: true)),
            ..._aiSuggestedTags
                .where((tag) => !_tags.contains(tag))
                .map((tag) => _buildTagChip(tag, isAiSuggested: true)),
            _buildAddTagButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag,
      {bool isRemovable = false, bool isAiSuggested = false}) {
    return Chip(
      label: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: isAiSuggested ? AppColors.primaryBlue : null,
        ),
      ),
      avatar: isAiSuggested
          ? const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.primaryBlue,
            )
          : null,
      deleteIcon: isRemovable ? const Icon(Icons.close, size: 16) : null,
      onDeleted: isRemovable
          ? () {
              setState(() {
                _tags.remove(tag);
              });
            }
          : null,
      backgroundColor:
          isAiSuggested ? AppColors.primaryBlue.withValues(alpha: 0.1) : null,
      side: isAiSuggested
          ? BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3))
          : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAddTagButton() {
    return ActionChip(
      label: const Text('+ Add Tag'),
      onPressed: _showAddTagDialog,
      avatar: const Icon(Icons.add, size: 16),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _buildAiSuggestions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.05),
            AppColors.primaryLight.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Suggestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (_aiConfidence != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_aiConfidence! * 100).round()}% confident',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_aiEstimatedMinutes != null)
            _buildSuggestionItem(
              'Estimated Duration',
              '$_aiEstimatedMinutes minutes',
              Icons.timer,
            ),
          if (_aiSuggestedCategory != null &&
              _aiSuggestedCategory != _selectedCategory)
            _buildSuggestionItem(
              'Suggested Category',
              _getCategoryDisplayName(_aiSuggestedCategory!),
              Icons.category,
              onTap: () {
                setState(() {
                  _selectedCategory = _aiSuggestedCategory!;
                });
              },
            ),
          if (_aiSuggestedPriority != null &&
              _aiSuggestedPriority != _selectedPriority)
            _buildSuggestionItem(
              'Suggested Priority',
              _getPriorityDisplayName(_aiSuggestedPriority!),
              Icons.flag,
              onTap: () {
                setState(() {
                  _selectedPriority = _aiSuggestedPriority!;
                });
              },
            ),
          if (_aiTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Productivity Tips:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
            ),
            const SizedBox(height: 4),
            ..._aiTips.take(3).map((tip) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 12,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tip,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              '$title: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: AppColors.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Consumer<SmartTaskProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.isLoading ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.editingTask != null
                            ? 'Update Task'
                            : 'Create Task',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Icon _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.coding:
        return const Icon(Icons.code, size: 18);
      case TaskCategory.writing:
        return const Icon(Icons.edit, size: 18);
      case TaskCategory.meeting:
        return const Icon(Icons.people, size: 18);
      case TaskCategory.research:
        return const Icon(Icons.search, size: 18);
      case TaskCategory.design:
        return const Icon(Icons.palette, size: 18);
      case TaskCategory.planning:
        return const Icon(Icons.event_note, size: 18);
      case TaskCategory.review:
        return const Icon(Icons.rate_review, size: 18);
      case TaskCategory.testing:
        return const Icon(Icons.bug_report, size: 18);
      case TaskCategory.documentation:
        return const Icon(Icons.description, size: 18);
      case TaskCategory.communication:
        return const Icon(Icons.message, size: 18);
      default:
        return const Icon(Icons.task, size: 18);
    }
  }

  String _getCategoryDisplayName(TaskCategory category) {
    return category.name.toUpperCase();
  }

  Icon _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return const Icon(Icons.emergency, size: 18, color: AppColors.error);
      case TaskPriority.high:
        return const Icon(Icons.priority_high,
            size: 18, color: AppColors.warning);
      case TaskPriority.medium:
        return const Icon(Icons.remove, size: 18, color: AppColors.info);
      case TaskPriority.low:
        return const Icon(Icons.arrow_downward,
            size: 18, color: AppColors.success);
    }
  }

  String _getPriorityDisplayName(TaskPriority priority) {
    return priority.name.toUpperCase();
  }

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate != null) {
      setState(() {
        _dueDate = selectedDate;
      });
    }
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTagDialog(
        existingTags: _tags,
        onTagAdded: (tag) {
          setState(() {
            if (!_tags.contains(tag)) {
              _tags.add(tag);
            }
          });
        },
      ),
    );
  }

  Future<void> _triggerAiAnalysis() async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
    });
    try {
      final provider = Provider.of<SmartTaskProvider>(context, listen: false);

      // Simulate AI analysis (in real implementation, this would call the AI service)
      await Future.delayed(const Duration(seconds: 2));
      // Mock AI suggestions - in real implementation, get from TaskIntelligenceEngine
      setState(() {
        _aiSuggestedCategory = TaskCategory.coding; // Example
        _aiSuggestedPriority = TaskPriority.medium;
        _aiSuggestedTags = ['urgent', 'feature', 'backend'];
        _aiEstimatedMinutes = 45;
        _aiConfidence = 0.85;
        _aiTips = [
          'Consider breaking this into smaller subtasks',
          'Schedule during your peak focus hours',
          'Prepare development environment beforehand',
        ];
        _showAiSuggestions = true;
      });
    } catch (e) {
      debugPrint('Error in AI analysis: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final provider = Provider.of<SmartTaskProvider>(context, listen: false);
      if (widget.editingTask != null) {
        // Update existing task
        final updatedTask = widget.editingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: _tags,
        );

        await provider.updateTask(updatedTask);
      } else {
        // Create new task with AI assistance
        await provider.createTaskWithAI(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          dueDate: _dueDate,
          tags: _tags,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onTaskCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _AddTagDialog extends StatefulWidget {
  final List<String> existingTags;
  final Function(String) onTagAdded;
  const _AddTagDialog({
    required this.existingTags,
    required this.onTagAdded,
  });
  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _tagController = TextEditingController();
  final _suggestedTags = [
    'urgent',
    'important',
    'quick',
    'research',
    'meeting',
    'coding',
    'design',
    'testing',
    'documentation',
    'review'
  ];
  @override
  Widget build(BuildContext context) {
    final availableSuggestions = _suggestedTags
        .where((tag) => !widget.existingTags.contains(tag))
        .toList();
    return AlertDialog(
      title: const Text('Add Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              hintText: 'Enter tag name',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _addTag(value),
          ),
          if (availableSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Suggested tags:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: availableSuggestions.map((tag) {
                return ActionChip(
                  label: Text(tag),
                  onPressed: () => _addTag(tag),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _addTag(_tagController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !widget.existingTags.contains(trimmedTag)) {
      widget.onTagAdded(trimmedTag);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
}
