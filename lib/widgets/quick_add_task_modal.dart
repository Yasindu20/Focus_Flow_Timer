import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/enhanced_task.dart';

/// Smart quick-add task modal with natural language parsing
class QuickAddTaskModal extends StatefulWidget {
  const QuickAddTaskModal({super.key});

  @override
  State<QuickAddTaskModal> createState() => _QuickAddTaskModalState();
}

class _QuickAddTaskModalState extends State<QuickAddTaskModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  
  String _parsedTitle = '';
  TaskPriority _parsedPriority = TaskPriority.medium;
  TaskCategory _parsedCategory = TaskCategory.general;
  DateTime? _parsedDueDate;
  int _parsedEstimatedMinutes = 25;
  List<String> _parsedTags = [];
  
  bool _showAdvanced = false;
  bool _isCreating = false;

  // Smart parsing patterns
  final _priorityPatterns = {
    TaskPriority.critical: ['urgent', 'critical', '!!!', 'asap', 'emergency'],
    TaskPriority.high: ['important', 'high', '!!', 'priority'],
    TaskPriority.medium: ['medium', '!'],
    TaskPriority.low: ['low', 'someday', 'maybe'],
  };

  final _categoryPatterns = {
    TaskCategory.coding: ['code', 'develop', 'program', 'fix', 'debug', 'implement'],
    TaskCategory.writing: ['write', 'blog', 'article', 'documentation', 'content'],
    TaskCategory.meeting: ['meeting', 'call', 'standup', 'interview', 'discuss'],
    TaskCategory.design: ['design', 'mockup', 'wireframe', 'ui', 'ux', 'sketch'],
    TaskCategory.research: ['research', 'study', 'analyze', 'investigate', 'explore'],
    TaskCategory.review: ['review', 'check', 'verify', 'approve', 'feedback'],
    TaskCategory.planning: ['plan', 'organize', 'schedule', 'roadmap', 'strategy'],
  };

  final _timePatterns = {
    r'\b(\d+)\s*(h|hr|hour|hours)\b': (match) => int.parse(match.group(1)!) * 60,
    r'\b(\d+)\s*(m|min|minute|minutes)\b': (match) => int.parse(match.group(1)!),
    r'\b(\d+)\s*(pomodoro|pomodoros)\b': (match) => int.parse(match.group(1)!) * 25,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextListeners();
    
    // Auto-focus input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _scaleController.forward();
  }

  void _setupTextListeners() {
    _textController.addListener(_parseInput);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _scaleAnimation]),
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _dismissModal(),
          child: Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            body: SafeArea(
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildModalContent(isDark),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalContent(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return GestureDetector(
      onTap: () {}, // Prevent dismiss when tapping modal content
      child: Container(
        width: screenWidth - (isVeryCompact ? 16 : 48),
        margin: EdgeInsets.symmetric(horizontal: isVeryCompact ? 8 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalHeader(isDark),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputSection(isDark, isVeryCompact),
                      if (_textController.text.isNotEmpty) ...[
                        _buildParsedPreview(isDark, isVeryCompact),
                        _buildAdvancedToggle(isDark),
                      ],
                      if (_showAdvanced) _buildAdvancedOptions(isDark, isVeryCompact),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(isDark, isVeryCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isVeryCompact ? 16 : 20),
      child: Row(
        children: [
          Container(
            width: isVeryCompact ? 36 : 40,
            height: isVeryCompact ? 36 : 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_task_rounded,
              color: Colors.white,
              size: isVeryCompact ? 18 : 20,
            ),
          ),
          SizedBox(width: isVeryCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add Task',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isVeryCompact ? 18 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isVeryCompact) // Hide subtitle on very small screens
                  Text(
                    'Type naturally and I\'ll parse it for you',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: isVeryCompact ? 13 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: isVeryCompact ? 8 : 12),
          GestureDetector(
            onTap: _dismissModal,
            child: Container(
              width: isVeryCompact ? 32 : 36,
              height: isVeryCompact ? 32 : 36,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(isVeryCompact ? 16 : 18),
              ),
              child: Icon(
                Icons.close_rounded,
                size: isVeryCompact ? 16 : 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark, bool isVeryCompact) {
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isVeryCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNode.hasFocus
              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: 3,
        minLines: 1,
        style: TextStyle(
          fontSize: isVeryCompact ? 14 : 16,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: isVeryCompact 
              ? 'e.g., "Review urgent 1h"' 
              : 'e.g., "Review pull request urgent 1h" or "Meeting with team tomorrow"',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: isVeryCompact ? 12 : 15,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isVeryCompact ? 12 : 20),
        ),
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _createTask(),
      ),
    );
  }

  Widget _buildParsedPreview(bool isDark, bool isVeryCompact) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        isVeryCompact ? 16 : 20, 
        16, 
        isVeryCompact ? 16 : 20, 
        0
      ),
      padding: EdgeInsets.all(isVeryCompact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.1),
                ]
              : [
                  Colors.blue.withValues(alpha: 0.05),
                  Colors.purple.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: isVeryCompact ? 14 : 16,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: isVeryCompact ? 6 : 8),
              Flexible(
                child: Text(
                  'Smart Parse Preview',
                  style: TextStyle(
                    fontSize: isVeryCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            'Title',
            _parsedTitle.isNotEmpty ? _parsedTitle : 'No title detected',
            Icons.title_rounded,
            isDark,
          ),
          _buildPreviewRow(
            'Priority',
            _parsedPriority.name.toUpperCase(),
            Icons.priority_high_rounded,
            isDark,
            color: _getPriorityColor(_parsedPriority),
          ),
          _buildPreviewRow(
            'Category',
            _parsedCategory.name.toLowerCase(),
            Icons.category_rounded,
            isDark,
            color: _getCategoryColor(_parsedCategory),
          ),
          if (_parsedDueDate != null)
            _buildPreviewRow(
              'Due Date',
              _formatDate(_parsedDueDate!),
              Icons.schedule_rounded,
              isDark,
              color: Colors.orange,
            ),
          _buildPreviewRow(
            'Estimated Time',
            '$_parsedEstimatedMinutes minutes',
            Icons.timer_rounded,
            isDark,
          ),
          if (_parsedTags.isNotEmpty)
            _buildPreviewRow(
              'Tags',
              _parsedTags.join(', '),
              Icons.tag_rounded,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isVeryCompact ? 6 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: isVeryCompact ? 12 : 14,
            color: color ?? (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          SizedBox(width: isVeryCompact ? 6 : 8),
          Flexible(
            flex: 1,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: isVeryCompact ? 11 : 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: isVeryCompact ? 4 : 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isVeryCompact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: color ?? (isDark ? Colors.white : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isVeryCompact ? 16 : 20, 
          12, 
          isVeryCompact ? 16 : 20, 
          0
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isVeryCompact ? 12 : 16, 
          vertical: isVeryCompact ? 10 : 12
        ),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showAdvanced 
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              _showAdvanced ? 'Hide Advanced' : 'Show Advanced',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(bool isDark, bool isVeryCompact) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        isVeryCompact ? 16 : 20, 
        12, 
        isVeryCompact ? 16 : 20, 
        0
      ),
      padding: EdgeInsets.all(isVeryCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDropdownField(
            'Priority',
            _parsedPriority.name.toUpperCase(),
            TaskPriority.values.map((p) => 
              DropdownMenuItem(
                value: p,
                child: Text(p.name.toUpperCase()),
              ),
            ).toList(),
            (value) => setState(() => _parsedPriority = value!),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            'Category',
            _parsedCategory.name.toLowerCase(),
            TaskCategory.values.map((c) => 
              DropdownMenuItem(
                value: c,
                child: Text(c.name.toLowerCase()),
              ),
            ).toList(),
            (value) => setState(() => _parsedCategory = value!),
            isDark,
          ),
          const SizedBox(height: 12),
          _buildTimeSlider(isDark),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    String value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isVeryCompact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isVeryCompact ? 8 : 12, 
            vertical: isVeryCompact ? 6 : 8
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey[300]!,
            ),
          ),
          child: DropdownButton<T>(
            value: items.map((e) => e.value).contains(value) ? null : items.first.value,
            items: items.map((item) => DropdownMenuItem<T>(
              value: item.value,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  item.child.toString().replaceAll('Text("', '').replaceAll('")', ''),
                  style: TextStyle(
                    fontSize: isVeryCompact ? 12 : 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            style: TextStyle(
              fontSize: isVeryCompact ? 12 : 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlider(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Estimated Time',
                style: TextStyle(
                  fontSize: isVeryCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_parsedEstimatedMinutes min',
              style: TextStyle(
                fontSize: isVeryCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: isVeryCompact ? 4 : 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            trackHeight: isVeryCompact ? 3 : 4,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: isVeryCompact ? 8 : 10,
            ),
          ),
          child: Slider(
            value: _parsedEstimatedMinutes.toDouble(),
            min: 15,
            max: 240,
            divisions: 9,
            onChanged: (value) => setState(() => _parsedEstimatedMinutes = value.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, bool isVeryCompact) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.all(isVeryCompact ? 12 : 20),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _dismissModal,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isVeryCompact ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isVeryCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: isVeryCompact ? 8 : 12),
          Expanded(
            flex: isVeryCompact ? 1 : 2,
            child: FilledButton(
              onPressed: _textController.text.trim().isNotEmpty && !_isCreating
                  ? _createTask
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(vertical: isVeryCompact ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCreating
                  ? SizedBox(
                      width: isVeryCompact ? 16 : 20,
                      height: isVeryCompact ? 16 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : Text(
                      isVeryCompact ? 'Create' : 'Create Task',
                      style: TextStyle(
                        fontSize: isVeryCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Smart parsing logic
  void _parseInput() {
    final input = _textController.text.toLowerCase();
    if (input.isEmpty) return;

    // Reset to defaults
    _parsedTitle = _textController.text;
    _parsedPriority = TaskPriority.medium;
    _parsedCategory = TaskCategory.general;
    _parsedDueDate = null;
    _parsedEstimatedMinutes = 25;
    _parsedTags = [];

    String cleanInput = input;

    // Parse priority
    for (final entry in _priorityPatterns.entries) {
      for (final pattern in entry.value) {
        if (input.contains(pattern)) {
          _parsedPriority = entry.key;
          cleanInput = cleanInput.replaceAll(pattern, '').trim();
          break;
        }
      }
    }

    // Parse category
    for (final entry in _categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (input.contains(pattern)) {
          _parsedCategory = entry.key;
          break;
        }
      }
    }

    // Parse time estimates
    for (final entry in _timePatterns.entries) {
      final regex = RegExp(entry.key, caseSensitive: false);
      final match = regex.firstMatch(input);
      if (match != null) {
        _parsedEstimatedMinutes = entry.value(match);
        cleanInput = cleanInput.replaceAll(regex, '').trim();
        break;
      }
    }

    // Parse due dates
    if (input.contains('today')) {
      _parsedDueDate = DateTime.now();
      cleanInput = cleanInput.replaceAll('today', '').trim();
    } else if (input.contains('tomorrow')) {
      _parsedDueDate = DateTime.now().add(const Duration(days: 1));
      cleanInput = cleanInput.replaceAll('tomorrow', '').trim();
    }

    // Parse hashtags as tags
    final tagRegex = RegExp(r'#(\w+)');
    final tagMatches = tagRegex.allMatches(input);
    _parsedTags = tagMatches.map((match) => match.group(1)!).toList();
    cleanInput = cleanInput.replaceAll(tagRegex, '').trim();

    // Clean up the title
    _parsedTitle = cleanInput
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();
    
    if (_parsedTitle.isEmpty) {
      _parsedTitle = _textController.text;
    }

    setState(() {});
  }

  // Helper methods
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.coding:
        return Colors.blue;
      case TaskCategory.writing:
        return Colors.green;
      case TaskCategory.meeting:
        return Colors.orange;
      case TaskCategory.design:
        return Colors.purple;
      case TaskCategory.research:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    
    return '${date.day}/${date.month}';
  }

  void _createTask() async {
    if (_parsedTitle.trim().isEmpty || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      await taskProvider.addTask(
        title: _parsedTitle,
        description: '',
        priority: _parsedPriority.name,
        estimatedMinutes: _parsedEstimatedMinutes,
      );

      HapticFeedback.mediumImpact();
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "$_parsedTitle" created successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _dismissModal() {
    _focusNode.unfocus();
    _slideController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }
}