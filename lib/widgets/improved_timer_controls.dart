import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/enums/timer_enums.dart';
import '../core/constants/colors.dart';
import '../core/utils/responsive_utils.dart';

class ImprovedTimerControls extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onSkip;
  final TimerState state;
  final String? currentTaskName;
  final int sessionCount;

  const ImprovedTimerControls({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSkip,
    required this.state,
    this.currentTaskName,
    this.sessionCount = 0,
  });

  @override
  State<ImprovedTimerControls> createState() => _ImprovedTimerControlsState();
}

class _ImprovedTimerControlsState extends State<ImprovedTimerControls>
    with TickerProviderStateMixin {
  late AnimationController _primaryButtonController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _primaryButtonScale;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showSecondaryActions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _primaryButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _primaryButtonScale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _primaryButtonController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Auto-pulse for running state
    _updatePulseState();
  }

  void _updatePulseState() {
    if (widget.state == TimerState.running && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != TimerState.running) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void didUpdateWidget(ImprovedTimerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updatePulseState();
      // Auto-hide secondary actions when state changes
      if (_showSecondaryActions && widget.state == TimerState.idle) {
        _toggleSecondaryActions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? (isSmallMobile ? 16 : 20) : 24,
        vertical: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context info (task name, session count)
          if (widget.state != TimerState.idle) ...[
            _buildContextInfo(isMobile),
            SizedBox(height: isMobile ? 12 : 16),
          ],

          // Primary action button
          _buildPrimaryButton(isMobile, isSmallMobile),

          // Animated secondary actions
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showSecondaryActions
                ? SlideTransition(
                    position: _slideAnimation,
                    child: _buildSecondaryActions(isMobile, isSmallMobile),
                  )
                : const SizedBox.shrink(),
          ),

          // Action toggle button (only show when timer is active)
          if (widget.state != TimerState.idle) ...[
            const SizedBox(height: 8),
            _buildActionToggle(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildContextInfo(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: _getContextColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getContextColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getContextIcon(),
            size: isMobile ? 14 : 16,
            color: _getContextColor(),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _getContextText(),
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: _getContextColor(),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(bool isMobile, bool isSmallMobile) {
    final buttonData = _getPrimaryButtonData();
    
    return AnimatedBuilder(
      animation: Listenable.merge([_primaryButtonScale, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _primaryButtonScale.value * 
                 (widget.state == TimerState.running ? _pulseAnimation.value : 1.0),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? (isSmallMobile ? 8 : 12) : 16,
            ),
            child: Material(
              elevation: widget.state == TimerState.running ? 12 : 8,
              borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
                  gradient: LinearGradient(
                    colors: [
                      buttonData.color,
                      buttonData.color.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: buttonData.color.withValues(alpha: 0.4),
                      blurRadius: widget.state == TimerState.running ? 20 : 15,
                      offset: const Offset(0, 8),
                      spreadRadius: widget.state == TimerState.running ? 0 : -2,
                    ),
                  ],
                ),
                child: Semantics(
                  button: true,
                  label: '${buttonData.label} timer',
                  hint: 'Tap to ${buttonData.label.toLowerCase()} the focus session',
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(isMobile ? 28 : 32),
                      onTap: _handlePrimaryAction,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? (isSmallMobile ? 24 : 32) : 40,
                          vertical: isMobile ? (isSmallMobile ? 12 : 16) : 20,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                buttonData.icon,
                                key: ValueKey(buttonData.icon),
                                color: Colors.white,
                                size: isMobile ? (isSmallMobile ? 20 : 24) : 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                buttonData.label,
                                key: ValueKey(buttonData.label),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? (isSmallMobile ? 14 : 16) : 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryActions(bool isMobile, bool isSmallMobile) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSecondaryButton(
            icon: Icons.stop_rounded,
            label: 'Stop',
            color: AppColors.error,
            onPressed: widget.state != TimerState.idle ? _handleStop : null,
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
          const SizedBox(width: 12),
          _buildSecondaryButton(
            icon: Icons.skip_next_rounded,
            label: 'Skip',
            color: AppColors.warning,
            onPressed: (widget.state == TimerState.running ||
                    widget.state == TimerState.paused)
                ? _handleSkip
                : null,
            isMobile: isMobile,
            isSmallMobile: isSmallMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final isEnabled = onPressed != null;

    return Expanded(
      child: Container(
        constraints: BoxConstraints(
          minHeight: isMobile ? (isSmallMobile ? 48 : 52) : 56,
        ),
        child: Semantics(
          button: true,
          enabled: isEnabled,
          label: '$label button',
          hint: isEnabled ? 'Tap to $label' : '$label is not available',
          child: Material(
            elevation: isEnabled ? 4 : 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withValues(alpha: 0.1)
                    : AppColors.progressTrack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? color.withValues(alpha: 0.3)
                      : AppColors.progressTrack,
                  width: isEnabled ? 1.5 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: isEnabled ? onPressed : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            icon,
                            key: ValueKey(icon),
                            color: isEnabled ? color : AppColors.textTertiary,
                            size: isMobile ? (isSmallMobile ? 18 : 20) : 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isEnabled ? color : AppColors.textTertiary,
                              fontSize: isMobile ? (isSmallMobile ? 10 : 11) : 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionToggle(bool isMobile) {
    return Semantics(
      button: true,
      label: _showSecondaryActions ? 'Hide timer options' : 'Show timer options',
      hint: 'Tap to ${_showSecondaryActions ? 'hide' : 'show'} additional timer controls',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _toggleSecondaryActions,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showSecondaryActions ? 'Less' : 'More',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _showSecondaryActions ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: isMobile ? 16 : 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSecondaryActions() {
    setState(() {
      _showSecondaryActions = !_showSecondaryActions;
    });
    
    if (_showSecondaryActions) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
    
    _hapticFeedback();
  }

  _PrimaryButtonData _getPrimaryButtonData() {
    switch (widget.state) {
      case TimerState.idle:
      case TimerState.completed:
        return _PrimaryButtonData(
          icon: Icons.play_arrow_rounded,
          label: 'Start Focus',
          color: AppColors.success,
        );
      case TimerState.running:
        return _PrimaryButtonData(
          icon: Icons.pause_rounded,
          label: 'Pause',
          color: AppColors.warning,
        );
      case TimerState.paused:
      case TimerState.cancelled:
        return _PrimaryButtonData(
          icon: Icons.play_arrow_rounded,
          label: 'Resume',
          color: AppColors.primaryBlue,
        );
    }
  }

  Color _getContextColor() {
    switch (widget.state) {
      case TimerState.running:
        return AppColors.success;
      case TimerState.paused:
        return AppColors.warning;
      case TimerState.completed:
        return AppColors.primaryBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getContextIcon() {
    switch (widget.state) {
      case TimerState.running:
        return Icons.timer_rounded;
      case TimerState.paused:
        return Icons.pause_circle_outline;
      case TimerState.completed:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getContextText() {
    if (widget.currentTaskName != null && widget.currentTaskName!.isNotEmpty) {
      return widget.currentTaskName!;
    }
    
    switch (widget.state) {
      case TimerState.running:
        return 'Focus Session • ${widget.sessionCount + 1}';
      case TimerState.paused:
        return 'Session Paused • ${widget.sessionCount + 1}';
      case TimerState.completed:
        return 'Session Complete!';
      default:
        return 'Ready to Focus';
    }
  }

  void _handlePrimaryAction() {
    _animatePrimaryButton();
    _hapticFeedback();

    switch (widget.state) {
      case TimerState.idle:
      case TimerState.completed:
        widget.onStart();
        break;
      case TimerState.running:
        widget.onPause();
        break;
      case TimerState.paused:
      case TimerState.cancelled:
        widget.onResume();
        break;
    }
  }

  void _handleStop() {
    _hapticFeedback();
    widget.onStop();
    _toggleSecondaryActions(); // Auto-hide after action
  }

  void _handleSkip() {
    _hapticFeedback();
    widget.onSkip();
    _toggleSecondaryActions(); // Auto-hide after action
  }

  void _animatePrimaryButton() {
    _primaryButtonController.forward().then((_) {
      _primaryButtonController.reverse();
    });
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _primaryButtonController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

class _PrimaryButtonData {
  final IconData icon;
  final String label;
  final Color color;

  _PrimaryButtonData({
    required this.icon,
    required this.label,
    required this.color,
  });
}