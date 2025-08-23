import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/advanced_timer_service.dart';

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
        icon = Icons.play_arrow;
        label = 'Start';
        color = Colors.green;
        onPressed = _handleMainAction;
        break;
      case TimerState.running:
        icon = Icons.pause;
        label = 'Pause';
        color = Colors.orange;
        onPressed = _handleMainAction;
        break;
      case TimerState.paused:
      case TimerState.interrupted:
        icon = Icons.play_arrow;
        label = 'Resume';
        color = Colors.blue;
        onPressed = _handleMainAction;
        break;
      case TimerState.recovering:
        icon = Icons.restore;
        label = 'Recover';
        color = Colors.purple;
        onPressed = _handleMainAction;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        heroTag: 'main_timer_button',
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
                icon: Icons.stop,
                label: 'Stop',
                color: Colors.red,
                onPressed: widget.state != TimerState.idle ? _handleStop : null,
              ),

              // Skip button
              _buildSecondaryButton(
                icon: Icons.skip_next,
                label: 'Skip',
                color: Colors.grey[600]!,
                onPressed: (widget.state == TimerState.running ||
                        widget.state == TimerState.paused)
                    ? _handleSkip
                    : null,
              ),

              // Settings button
              _buildSecondaryButton(
                icon: Icons.settings,
                label: 'Settings',
                color: Colors.grey[600]!,
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

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _animateSecondaryButton() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isEnabled
                ? color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      case TimerState.interrupted:
      case TimerState.recovering:
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
