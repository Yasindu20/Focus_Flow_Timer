import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/focus_analytics_service.dart';
import '../core/constants/colors.dart';
import '../screens/focus_settings_screen.dart';
import '../screens/focus_analytics_screen.dart';

class FocusDashboardWidget extends StatelessWidget {
  const FocusDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFocusModeToggle(context, timerProvider),
              const SizedBox(height: 16),
              _buildQuickStats(context, timerProvider),
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusModeToggle(BuildContext context, EnhancedTimerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.focusModeEnabled 
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: provider.focusModeEnabled ? AppColors.primaryBlue : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Focus Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  provider.focusModeEnabled 
                      ? 'Enhanced focus features enabled'
                      : 'Tap to enable advanced focus features',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: provider.focusModeEnabled,
            onChanged: (value) async {
              await provider.enableFocusMode(value);
            },
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, EnhancedTimerProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Level',
            '${provider.currentLevel}',
            Icons.star,
            AppColors.workColor,
            subtitle: '${provider.currentXP} XP',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Streak',
            '${FocusAnalyticsService().currentStreak.days}',
            Icons.local_fire_department,
            AppColors.warning,
            subtitle: 'days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Badges',
            '${provider.earnedBadges.length}',
            Icons.emoji_events,
            AppColors.success,
            subtitle: 'earned',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FocusAnalyticsScreen()),
              );
            },
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('Analytics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FocusSettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}