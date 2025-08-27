import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/enhanced_task.dart';

/// Modern, mobile-first task card with rich visual hierarchy and interactions
class EnhancedTaskCard extends StatefulWidget {
  final EnhancedTask task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onStartPomodoro;
  final bool showActions;
  final bool isSelected;

  const EnhancedTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.onEdit,
    this.onStartPomodoro,
    this.showActions = true,
    this.isSelected = false,
  });

  @override
  State<EnhancedTaskCard> createState() => _EnhancedTaskCardState();
}

class _EnhancedTaskCardState extends State<EnhancedTaskCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  bool _isSwipeActionVisible = false;
  bool _showSubtasks = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.task.completionPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _progressController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: 6,
            ),
            child: Stack(
              children: [
                // Background swipe actions
                if (_isSwipeActionVisible) _buildSwipeActions(isDark),
                
                // Main card with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainCard(isDark, isCompact),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(bool isDark, bool isCompact) {
    return GestureDetector(
      onTap: () {
        _scaleController.forward().then((_) => _scaleController.reverse());
        widget.onTap?.call();
        HapticFeedback.lightImpact();
      },
      onPanStart: (details) => _handlePanStart(),
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        decoration: _buildCardDecoration(isDark),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildCardHeader(isDark, isCompact),
              if (widget.task.description.isNotEmpty || widget.task.subtasks.isNotEmpty)
                _buildCardBody(isDark, isCompact),
              _buildCardFooter(isDark, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(bool isDark) {
    final urgency = widget.task.urgency;
    final baseColor = _getUrgencyColor(urgency);
    
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.grey[850]!.withValues(alpha: 0.9),
                Colors.grey[900]!.withValues(alpha: 0.95),
              ]
            : [
                Colors.white,
                Colors.grey[50]!,
              ],
      ),
      border: Border.all(
        color: widget.isSelected
            ? Theme.of(context).primaryColor
            : (widget.task.isOverdue
                ? Colors.red.withValues(alpha: 0.3)
                : baseColor.withValues(alpha: 0.2)),
        width: widget.isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.1),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        if (widget.isSelected)
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
      ],
    );
  }

  Widget _buildCardHeader(bool isDark, bool isCompact) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriorityIndicator(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskTitle(isDark, isCompact),
                const SizedBox(height: 4),
                _buildTaskMetadata(isDark, isCompact),
              ],
            ),
          ),
          if (widget.showActions) _buildQuickActions(isDark, isCompact),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    final urgency = widget.task.urgency;
    final color = _getUrgencyColor(urgency);
    final icon = _getUrgencyIcon(urgency);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (widget.task.isOverdue)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskTitle(bool isDark, bool isCompact) {
    return Text(
      widget.task.title,
      style: TextStyle(
        fontSize: isCompact ? 15 : 16,
        fontWeight: FontWeight.w600,
        color: widget.task.isCompleted
            ? (isDark ? Colors.grey[400] : Colors.grey[600])
            : (isDark ? Colors.white : Colors.black87),
        decoration: widget.task.isCompleted 
            ? TextDecoration.lineThrough 
            : null,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTaskMetadata(bool isDark, bool isCompact) {
    final metadata = <Widget>[];
    
    // Due date
    if (widget.task.dueDate != null) {
      metadata.add(_buildMetadataChip(
        icon: Icons.schedule_rounded,
        text: _formatDueDate(widget.task.dueDate!),
        color: widget.task.isOverdue ? Colors.red : Colors.orange,
        isDark: isDark,
        isCompact: isCompact,
      ));
    }
    
    // Pomodoro progress
    if (widget.task.estimatedPomodoros > 0) {
      metadata.add(_buildMetadataChip(
        icon: Icons.timer_rounded,
        text: '${widget.task.completedPomodoros}/${widget.task.estimatedPomodoros}',
        color: Colors.blue,
        isDark: isDark,
        isCompact: isCompact,
      ));
    }
    
    // Subtasks count
    if (widget.task.subtasks.isNotEmpty) {
      final completed = widget.task.subtasks.where((s) => s.isCompleted).length;
      metadata.add(_buildMetadataChip(
        icon: Icons.checklist_rounded,
        text: '$completed/${widget.task.subtasks.length}',
        color: Colors.green,
        isDark: isDark,
        isCompact: isCompact,
      ));
    }

    // Use Wrap with constrained spacing for better mobile layout
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = screenWidth < 360 ? 4.0 : 8.0;
    
    return Wrap(
      spacing: spacing,
      runSpacing: 4,
      children: metadata,
    );
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
    required bool isCompact,
  }) {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    // Responsive sizing
    final horizontalPadding = isVeryCompact ? 4.0 : (isCompact ? 6.0 : 8.0);
    final iconSize = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
    final fontSize = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 12.0);
    final spacing = isVeryCompact ? 2.0 : 4.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: color,
          ),
          SizedBox(width: spacing),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, bool isCompact) {
    // Calculate maximum available width for actions
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    // For very small screens, show fewer actions to prevent overflow
    if (isVeryCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show only the most important action on very small screens
          if (!widget.task.isCompleted && widget.onComplete != null)
            _buildActionButton(
              icon: Icons.check_rounded,
              onTap: widget.onComplete!,
              color: Colors.green,
              isCompact: true,
            ),
          _buildActionButton(
            icon: Icons.more_vert_rounded,
            onTap: () => _showMoreActions(context),
            color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
            isCompact: true,
          ),
        ],
      );
    }
    
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.task.isCompleted && widget.onStartPomodoro != null)
            _buildActionButton(
              icon: Icons.play_arrow_rounded,
              onTap: widget.onStartPomodoro!,
              color: Theme.of(context).primaryColor,
              isCompact: isCompact,
            ),
          if (!widget.task.isCompleted && widget.onComplete != null)
            _buildActionButton(
              icon: Icons.check_rounded,
              onTap: widget.onComplete!,
              color: Colors.green,
              isCompact: isCompact,
            ),
          _buildActionButton(
            icon: Icons.more_vert_rounded,
            onTap: () => _showMoreActions(context),
            color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isCompact,
  }) {
    // Get screen width to determine sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    // Responsive sizing based on screen size
    final buttonSize = isVeryCompact ? 28 : (isCompact ? 32 : 36);
    final iconSize = isVeryCompact ? 14 : (isCompact ? 16 : 18);
    final margin = isVeryCompact ? 2.0 : 4.0;
    
    return Container(
      margin: EdgeInsets.only(left: margin),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            onTap();
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: buttonSize.toDouble(),
            height: buttonSize.toDouble(),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: iconSize.toDouble(),
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(bool isDark, bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.task.description.isNotEmpty) ...[
            Text(
              widget.task.description,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Progress bar
          if (widget.task.completionPercentage > 0)
            _buildProgressBar(isDark),
          
          // Subtasks preview
          if (widget.task.subtasks.isNotEmpty)
            _buildSubtasksPreview(isDark, isCompact),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '${widget.task.completionPercentage.round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: isDark 
                  ? Colors.grey[700]!.withValues(alpha: 0.3)
                  : Colors.grey[300]!.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUrgencyColor(widget.task.urgency),
              ),
              borderRadius: BorderRadius.circular(2),
              minHeight: 4,
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubtasksPreview(bool isDark, bool isCompact) {
    final subtasks = widget.task.subtasks.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSubtasks = !_showSubtasks),
          child: Row(
            children: [
              Icon(
                _showSubtasks 
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              Text(
                '${widget.task.subtasks.length} subtasks',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _showSubtasks 
              ? Column(
                  children: subtasks.map((subtask) =>
                    _buildSubtaskItem(subtask, isDark, isCompact)
                  ).toList(),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSubtaskItem(TaskSubtask subtask, bool isDark, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4),
      child: Row(
        children: [
          Icon(
            subtask.isCompleted 
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: subtask.isCompleted 
                ? Colors.green
                : (isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: subtask.isCompleted
                    ? (isDark ? Colors.grey[400] : Colors.grey[600])
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                decoration: subtask.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(bool isDark, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey[800]!.withValues(alpha: 0.3)
            : Colors.grey[50]!.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _buildCategoryChip(isDark, isCompact),
          const Spacer(),
          if (widget.task.timeSpent.inMinutes > 0)
            _buildTimeSpentIndicator(isDark, isCompact),
          _buildSwipeHint(isDark, isCompact),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(bool isDark, bool isCompact) {
    final category = widget.task.category;
    final color = _getCategoryColor(category);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        category.name.toUpperCase(),
        style: TextStyle(
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTimeSpentIndicator(bool isDark, bool isCompact) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: isCompact ? 12 : 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(widget.task.timeSpent),
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeHint(bool isDark, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.swipe_left_rounded,
          size: isCompact ? 12 : 14,
          color: isDark 
              ? Colors.grey[500]!.withValues(alpha: 0.6)
              : Colors.grey[400]!.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 2),
        Text(
          'Swipe',
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            color: isDark 
                ? Colors.grey[500]!.withValues(alpha: 0.8)
                : Colors.grey[400]!.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeActions(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.1),
              Colors.red.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            const Spacer(),
            _buildSwipeAction(
              icon: Icons.check_rounded,
              color: Colors.green,
              onTap: widget.onComplete,
            ),
            const SizedBox(width: 8),
            _buildSwipeAction(
              icon: Icons.delete_rounded,
              color: Colors.red,
              onTap: widget.onDelete,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeAction({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        HapticFeedback.mediumImpact();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Helper methods
  Color _getUrgencyColor(TaskUrgency urgency) {
    switch (urgency) {
      case TaskUrgency.critical:
        return Colors.red;
      case TaskUrgency.high:
        return Colors.orange;
      case TaskUrgency.medium:
        return Colors.blue;
      case TaskUrgency.low:
        return Colors.green;
    }
  }

  IconData _getUrgencyIcon(TaskUrgency urgency) {
    switch (urgency) {
      case TaskUrgency.critical:
        return Icons.priority_high_rounded;
      case TaskUrgency.high:
        return Icons.keyboard_arrow_up_rounded;
      case TaskUrgency.medium:
        return Icons.remove_rounded;
      case TaskUrgency.low:
        return Icons.keyboard_arrow_down_rounded;
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

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return '${difference}d';
    return '${(difference / 7).round()}w';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Gesture handling
  void _handlePanStart() {
    if (!widget.showActions) return;
    _scaleController.forward();
  }

  void _handlePanUpdate(details) {
    if (!widget.showActions) return;
    
    final dx = details.delta.dx;
    if (dx < -5) {
      setState(() => _isSwipeActionVisible = true);
      _slideController.forward();
    } else if (dx > 5 && _isSwipeActionVisible) {
      setState(() => _isSwipeActionVisible = false);
      _slideController.reverse();
    }
  }

  void _handlePanEnd(details) {
    if (!widget.showActions) return;
    
    _scaleController.reverse();
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity < -500) {
      // Fast swipe left - show actions
      setState(() => _isSwipeActionVisible = true);
      _slideController.forward();
    } else if (velocity > 500 && _isSwipeActionVisible) {
      // Fast swipe right - hide actions
      setState(() => _isSwipeActionVisible = false);
      _slideController.reverse();
    }
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreActionsSheet(
        task: widget.task,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onStartPomodoro: widget.onStartPomodoro,
      ),
    );
  }
}

/// Bottom sheet for additional task actions
class _MoreActionsSheet extends StatelessWidget {
  final EnhancedTask task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStartPomodoro;

  const _MoreActionsSheet({
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Actions
            if (onEdit != null)
              _buildActionTile(
                icon: Icons.edit_rounded,
                title: 'Edit Task',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            
            if (onStartPomodoro != null && !task.isCompleted)
              _buildActionTile(
                icon: Icons.play_arrow_rounded,
                title: 'Start Pomodoro',
                onTap: () {
                  Navigator.pop(context);
                  onStartPomodoro?.call();
                },
              ),
            
            _buildActionTile(
              icon: Icons.schedule_rounded,
              title: 'Set Due Date',
              onTap: () {
                Navigator.pop(context);
                // Handle due date setting
              },
            ),
            
            _buildActionTile(
              icon: Icons.label_rounded,
              title: 'Add Tags',
              onTap: () {
                Navigator.pop(context);
                // Handle tag addition
              },
            ),
            
            if (onDelete != null)
              _buildActionTile(
                icon: Icons.delete_rounded,
                title: 'Delete Task',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}