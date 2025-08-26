import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/enums/timer_enums.dart';
import '../core/constants/colors.dart';

class TimerControls extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onSkip;
  final TimerState state;

  const TimerControls({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSkip,
    required this.state,
  });

  @override
  State<TimerControls> createState() => _TimerControlsState();
}

class _TimerControlsState extends State<TimerControls>
    with TickerProviderStateMixin {
  late AnimationController _primaryButtonController;
  late AnimationController _secondaryButtonController;
  late Animation<double> _primaryButtonScale;
  late Animation<double> _secondaryButtonScale;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _primaryButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _secondaryButtonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _primaryButtonScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _primaryButtonController,
      curve: Curves.easeInOut,
    ));

    _secondaryButtonScale = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(CurvedAnimation(
      parent: _secondaryButtonController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Primary control
          _buildPrimaryControl(),

          const SizedBox(height: 20),

          // Secondary controls
          _buildSecondaryControls(),
        ],
      ),
    );
  }

  Widget _buildPrimaryControl() {
    return AnimatedBuilder(
      animation: _primaryButtonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _primaryButtonScale.value,
          child: _buildMainActionButton(),
        );
      },
    );
  }

  Widget _buildMainActionButton() {
    IconData icon;
    String label;
    Color color;
    VoidCallback onPressed;

    switch (widget.state) {
      case TimerState.idle:
      case TimerState.completed:
        icon = Icons.play_arrow_rounded;
        label = 'Start';
        color = AppColors.success;
        onPressed = _handleMainAction;
        break;
      case TimerState.running:
        icon = Icons.pause_rounded;
        label = 'Pause';
        color = AppColors.warning;
        onPressed = _handleMainAction;
        break;
      case TimerState.paused:
      case TimerState.cancelled:
        icon = Icons.play_arrow_rounded;
        label = 'Resume';
        color = AppColors.primaryBlue;
        onPressed = _handleMainAction;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Semantics(
            button: true,
            label: '$label timer',
            hint: 'Tap to $label the focus session',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildSecondaryControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _secondaryButtonScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _secondaryButtonScale.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reset/Stop button
                Expanded(
                  child: _buildSecondaryButton(
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    color: AppColors.error,
                    onPressed: widget.state != TimerState.idle ? _handleStop : null,
                  ),
                ),

                const SizedBox(width: 12),

                // Skip button
                Expanded(
                  child: _buildSecondaryButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Skip',
                    color: AppColors.textSecondary,
                    onPressed: (widget.state == TimerState.running ||
                            widget.state == TimerState.paused)
                        ? _handleSkip
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                // Settings button
                Expanded(
                  child: _buildSecondaryButton(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    color: AppColors.textSecondary,
                    onPressed: _handleSettings,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: '$label button',
      hint: isEnabled ? 'Tap to $label' : '$label is not available right now',
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withValues(alpha: 0.08)
              : AppColors.progressTrack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? color.withValues(alpha: 0.15)
                : AppColors.progressTrack,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            onTapDown: isEnabled ? (_) => _animateSecondaryButton() : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isEnabled ? color : AppColors.textTertiary,
                        fontSize: 10,
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
    );
  }

  void _handleMainAction() {
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
    _animateSecondaryButton();
    _hapticFeedback();
    widget.onStop();
  }

  void _handleSkip() {
    _animateSecondaryButton();
    _hapticFeedback();
    widget.onSkip();
  }

  void _handleSettings() {
    _animateSecondaryButton();
    _hapticFeedback();
    // Navigate to settings
    Navigator.pushNamed(context, '/settings');
  }

  void _animatePrimaryButton() {
    _primaryButtonController.forward().then((_) {
      _primaryButtonController.reverse();
    });
  }

  void _animateSecondaryButton() {
    _secondaryButtonController.forward().then((_) {
      _secondaryButtonController.reverse();
    });
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _primaryButtonController.dispose();
    _secondaryButtonController.dispose();
    super.dispose();
  }
}
