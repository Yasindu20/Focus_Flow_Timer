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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Primary shadow
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          // Soft glow
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: '$label timer',
        hint: 'Double tap to $label the pomodoro session',
        child: FloatingActionButton.extended(
          heroTag: "timer_controls_fab",
          onPressed: onPressed,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
          icon: Icon(icon, size: 26),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return AnimatedBuilder(
      animation: _secondaryButtonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _secondaryButtonScale.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset/Stop button
              _buildSecondaryButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                color: AppColors.error,
                onPressed: widget.state != TimerState.idle ? _handleStop : null,
              ),

              // Skip button
              _buildSecondaryButton(
                icon: Icons.skip_next_rounded,
                label: 'Skip',
                color: AppColors.textSecondary,
                onPressed: (widget.state == TimerState.running ||
                        widget.state == TimerState.paused)
                    ? _handleSkip
                    : null,
              ),

              // Settings button
              _buildSecondaryButton(
                icon: Icons.tune_rounded,
                label: 'Settings',
                color: AppColors.textSecondary,
                onPressed: _handleSettings,
              ),
            ],
          ),
        );
      },
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          onTapDown: isEnabled ? (_) => _animateSecondaryButton() : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isEnabled
                  ? color.withValues(alpha: 0.08)
                  : AppColors.progressTrack,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEnabled
                    ? color.withValues(alpha: 0.2)
                    : AppColors.progressTrack,
                width: 1.5,
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: isEnabled ? color : AppColors.textTertiary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? color : AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
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
