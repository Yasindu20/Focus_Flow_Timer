import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../core/enums/timer_enums.dart';

class DurationSelector extends StatefulWidget {
  final TimerType timerType;
  final int currentDuration;
  final ValueChanged<int> onDurationChanged;
  final bool isCompact;

  const DurationSelector({
    super.key,
    required this.timerType,
    required this.currentDuration,
    required this.onDurationChanged,
    this.isCompact = false,
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _textController;
  bool _isCustomMode = false;

  // Predefined duration presets based on research
  Map<TimerType, List<int>> get _presets => {
        TimerType.pomodoro: [15, 25, 30, 45, 50, 60, 90],
        TimerType.shortBreak: [3, 5, 10, 15],
        TimerType.longBreak: [10, 15, 20, 30],
        TimerType.custom: [10, 15, 20, 25, 30, 45, 60, 90, 120],
      };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _textController = TextEditingController(
      text: widget.currentDuration.toString(),
    );
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isMobile),
          SizedBox(height: isMobile ? 16 : 20),
          if (!_isCustomMode) ...[
            _buildPresetGrid(isMobile),
            SizedBox(height: isMobile ? 12 : 16),
          ],
          _buildCustomDurationInput(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: _getTimerTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTimerTypeIcon(),
            color: _getTimerTypeColor(),
            size: isMobile ? 16 : 18,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.timerType.displayName} Duration',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Choose your preferred duration',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        _buildToggleButton(isMobile),
      ],
    );
  }

  Widget _buildToggleButton(bool isMobile) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _isCustomMode = !_isCustomMode;
          });
          HapticFeedback.lightImpact();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: _isCustomMode
                ? _getTimerTypeColor().withValues(alpha: 0.1)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCustomMode
                  ? _getTimerTypeColor().withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCustomMode ? Icons.tune_rounded : Icons.grid_view_rounded,
                size: isMobile ? 14 : 16,
                color: _isCustomMode ? _getTimerTypeColor() : AppColors.textSecondary,
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                _isCustomMode ? 'Custom' : 'Presets',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  color: _isCustomMode ? _getTimerTypeColor() : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGrid(bool isMobile) {
    final presets = _presets[widget.timerType] ?? [];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 4 : 5,
        crossAxisSpacing: isMobile ? 8 : 12,
        mainAxisSpacing: isMobile ? 8 : 12,
        childAspectRatio: isMobile ? 1.2 : 1.3,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final duration = presets[index];
        final isSelected = duration == widget.currentDuration;
        
        return _buildPresetButton(
          duration: duration,
          isSelected: isSelected,
          isMobile: isMobile,
          onTap: () {
            widget.onDurationChanged(duration);
            _textController.text = duration.toString();
            _animateSelection();
          },
        );
      },
    );
  }

  Widget _buildPresetButton({
    required int duration,
    required bool isSelected,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$duration minutes',
      hint: isSelected ? 'Currently selected' : 'Tap to select',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _pulseAnimation.value : 1.0,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getTimerTypeColor().withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getTimerTypeColor()
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$duration',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _getTimerTypeColor()
                              : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        'min',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? _getTimerTypeColor().withValues(alpha: 0.8)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomDurationInput(bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: _isCustomMode
            ? _getTimerTypeColor().withValues(alpha: 0.05)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCustomMode
              ? _getTimerTypeColor().withValues(alpha: 0.2)
              : AppColors.progressTrack,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_rounded,
            size: isMobile ? 16 : 18,
            color: _isCustomMode ? _getTimerTypeColor() : AppColors.textSecondary,
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter minutes',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (value) {
                _handleCustomDurationSubmit(value);
              },
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final duration = int.tryParse(value);
                  if (duration != null && duration > 0 && duration <= 999) {
                    setState(() {
                      _isCustomMode = true;
                    });
                  }
                }
              },
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _handleCustomDurationSubmit(_textController.text);
              },
              child: Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: _getTimerTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: isMobile ? 16 : 18,
                  color: _getTimerTypeColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCustomDurationSubmit(String value) {
    final duration = int.tryParse(value);
    if (duration != null && duration > 0 && duration <= 999) {
      widget.onDurationChanged(duration);
      _animateSelection();
      FocusScope.of(context).unfocus();
      HapticFeedback.selectionClick();
    } else {
      _showValidationError();
    }
  }

  void _showValidationError() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please enter a duration between 1 and 999 minutes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _animateSelection() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  Color _getTimerTypeColor() {
    switch (widget.timerType) {
      case TimerType.pomodoro:
        return AppColors.workColor;
      case TimerType.shortBreak:
      case TimerType.longBreak:
        return AppColors.breakColor;
      case TimerType.custom:
        return AppColors.primaryBlue;
    }
  }

  IconData _getTimerTypeIcon() {
    switch (widget.timerType) {
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
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }
}