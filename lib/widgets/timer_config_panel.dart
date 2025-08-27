import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../providers/timer_settings_provider.dart';
import '../core/constants/colors.dart';
import '../core/enums/timer_enums.dart';
import 'duration_selector.dart';

class TimerConfigPanel extends StatefulWidget {
  const TimerConfigPanel({super.key});

  @override
  State<TimerConfigPanel> createState() => _TimerConfigPanelState();
}

class _TimerConfigPanelState extends State<TimerConfigPanel>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Consumer2<EnhancedTimerProvider, TimerSettingsProvider>(
      builder: (context, timerProvider, settingsProvider, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? (screenWidth < 400 ? 0 : 4) : 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(timerProvider, isMobile),
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildExpandedContent(
                  timerProvider,
                  settingsProvider,
                  isMobile,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(EnhancedTimerProvider timerProvider, bool isMobile) {
    final canModify = timerProvider.state.isIdle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canModify ? _toggleExpanded : null,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Row(
            children: [
              // Timer type icon and info
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: _getTimerTypeColor(timerProvider.currentType)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTimerTypeIcon(timerProvider.currentType),
                  color: _getTimerTypeColor(timerProvider.currentType),
                  size: isMobile ? 20 : 24,
                ),
              ),
              
              SizedBox(width: isMobile ? 12 : 16),
              
              // Timer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timer Configuration',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            timerProvider.currentType.displayName,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: _getTimerTypeColor(timerProvider.currentType),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            ' • ${timerProvider.getCurrentCustomDuration()} min',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Quick timer type selector
              if (canModify) ...[
                _buildQuickTypeSelector(timerProvider, isMobile),
                SizedBox(width: isMobile ? 8 : 12),
              ],
              
              // Expand/collapse button
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.expand_more_rounded,
                  color: canModify ? AppColors.textSecondary : AppColors.textTertiary,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTypeSelector(EnhancedTimerProvider timerProvider, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimerType.values.take(3).map((type) {
          final isSelected = timerProvider.currentType == type;
          final color = _getTimerTypeColor(type);
          
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => timerProvider.updateTimerType(type),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTimerTypeIcon(type),
                  color: isSelected ? color : AppColors.textTertiary,
                  size: isMobile ? 16 : 18,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedContent(
    EnhancedTimerProvider timerProvider,
    TimerSettingsProvider settingsProvider,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        0,
        isMobile ? 16 : 20,
        isMobile ? 16 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.progressTrack,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Duration selector for current timer type
          DurationSelector(
            timerType: timerProvider.currentType,
            currentDuration: timerProvider.getCurrentCustomDuration(),
            onDurationChanged: (duration) {
              timerProvider.updateCustomDuration(duration);
            },
            isCompact: isMobile,
          ),

          SizedBox(height: isMobile ? 16 : 20),

          // Session flow preview
          _buildSessionFlowPreview(settingsProvider, isMobile),

          SizedBox(height: isMobile ? 16 : 20),

          // Quick actions
          _buildQuickActions(timerProvider, settingsProvider, isMobile),
        ],
      ),
    );
  }

  Widget _buildSessionFlowPreview(TimerSettingsProvider settingsProvider, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: isMobile ? 14 : 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'Session Flow Preview',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildFlowItems(settingsProvider, isMobile),
        ],
      ),
    );
  }

  Widget _buildFlowItems(TimerSettingsProvider settingsProvider, bool isMobile) {
    final workDuration = settingsProvider.workDuration;
    final shortBreakDuration = settingsProvider.shortBreakDuration;
    final longBreakDuration = settingsProvider.longBreakDuration;
    final longBreakInterval = settingsProvider.settings.longBreakInterval;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: isMobile ? 3 : 4,
          runSpacing: isMobile ? 3 : 4,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          children: [
            for (int i = 1; i <= longBreakInterval; i++) ...[
              _buildFlowChip(
                'Work $i',
                '${workDuration}m',
                AppColors.workColor,
                isMobile,
              ),
              if (i < longBreakInterval)
                _buildFlowChip(
                  'Break',
                  '${shortBreakDuration}m',
                  AppColors.breakColor,
                  isMobile,
                )
              else
                _buildFlowChip(
                  'Long Break',
                  '${longBreakDuration}m',
                  AppColors.breakColor,
                  isMobile,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFlowChip(String label, String duration, Color color, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 60,
        maxWidth: 120,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: isMobile ? 3 : 4),
          Text(
            duration,
            style: TextStyle(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w400,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    EnhancedTimerProvider timerProvider,
    TimerSettingsProvider settingsProvider,
    bool isMobile,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            label: 'Reset to Default',
            icon: Icons.restore_rounded,
            color: AppColors.textSecondary,
            isMobile: isMobile,
            onTap: () => _showResetDialog(settingsProvider),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: _buildQuickActionButton(
            label: 'Quick Start',
            icon: Icons.play_arrow_rounded,
            color: AppColors.success,
            isMobile: isMobile,
            onTap: () {
              _toggleExpanded();
              timerProvider.startTimer();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isMobile ? 16 : 18),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _showResetDialog(TimerSettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'This will reset all timer durations to their default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settingsProvider.resetToDefaults();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Color _getTimerTypeColor(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return AppColors.workColor;
      case TimerType.shortBreak:
      case TimerType.longBreak:
        return AppColors.breakColor;
      case TimerType.custom:
        return AppColors.primaryBlue;
    }
  }

  IconData _getTimerTypeIcon(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return Icons.work_rounded;
      case TimerType.shortBreak:
        return Icons.coffee_rounded;
      case TimerType.longBreak:
        return Icons.hotel_rounded;
      case TimerType.custom:
        return Icons.timer_rounded;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }
}