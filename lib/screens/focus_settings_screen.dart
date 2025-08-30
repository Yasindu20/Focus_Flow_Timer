import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/enhanced_timer_provider.dart';
import '../services/focus_mode_manager.dart';
import '../services/enhanced_audio_service.dart';
import '../services/focus_gamification_service.dart';
import '../core/constants/colors.dart';

class FocusSettingsScreen extends StatefulWidget {
  const FocusSettingsScreen({super.key});

  @override
  State<FocusSettingsScreen> createState() => _FocusSettingsScreenState();
}

class _FocusSettingsScreenState extends State<FocusSettingsScreen> {
  bool _focusModeEnabled = false;
  bool _autoDoNotDisturb = true;
  FocusBlockingLevel _blockingLevel = FocusBlockingLevel.moderate;
  bool _allowEmergencyCalls = true;
  FocusSoundProfile? _selectedSoundProfile;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
    final focusMode = FocusModeManager();
    
    setState(() {
      _focusModeEnabled = timerProvider.focusModeEnabled;
      _autoDoNotDisturb = focusMode.autoDoNotDisturb;
      _blockingLevel = focusMode.blockingLevel;
      _allowEmergencyCalls = focusMode.allowEmergencyCalls;
      _selectedSoundProfile = timerProvider.selectedSoundProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Focus Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('🎯 Focus Mode', 'Block distractions during focus sessions'),
            _buildFocusModeSection(),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('🔕 Notification Blocking', 'Control Do Not Disturb settings'),
            _buildNotificationSection(),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('🚫 App Blocking', 'Prevent access to distracting apps'),
            _buildAppBlockingSection(),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('🎵 Ambient Sounds', 'Choose focus-enhancing audio'),
            _buildAmbientSoundsSection(),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('🎮 Gamification', 'View your focus progress'),
            _buildGamificationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFocusModeSection() {
    return _buildSettingsCard([
      SwitchListTile(
        title: const Text('Enable Focus Mode'),
        subtitle: const Text('Activate enhanced focus features during sessions'),
        value: _focusModeEnabled,
        onChanged: (value) async {
          setState(() => _focusModeEnabled = value);
          final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
          await timerProvider.enableFocusMode(value);
        },
        activeColor: AppColors.primaryBlue,
      ),
    ]);
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard([
      SwitchListTile(
        title: const Text('Auto Do Not Disturb'),
        subtitle: const Text('Automatically silence notifications during focus'),
        value: _autoDoNotDisturb,
        onChanged: _focusModeEnabled ? (value) async {
          setState(() => _autoDoNotDisturb = value);
          final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
          await timerProvider.configureFocusSettings(autoDoNotDisturb: value);
        } : null,
        activeColor: AppColors.primaryBlue,
      ),
      const Divider(height: 1),
      SwitchListTile(
        title: const Text('Allow Emergency Calls'),
        subtitle: const Text('Let urgent calls through during focus'),
        value: _allowEmergencyCalls,
        onChanged: _focusModeEnabled && _autoDoNotDisturb ? (value) async {
          setState(() => _allowEmergencyCalls = value);
          final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
          await timerProvider.configureFocusSettings(allowEmergencyCalls: value);
        } : null,
        activeColor: AppColors.primaryBlue,
      ),
    ]);
  }

  Widget _buildAppBlockingSection() {
    return _buildSettingsCard([
      ListTile(
        title: const Text('Blocking Intensity'),
        subtitle: Text(_getBlockingLevelDescription(_blockingLevel)),
        trailing: DropdownButton<FocusBlockingLevel>(
          value: _blockingLevel,
          onChanged: _focusModeEnabled ? (value) async {
            if (value != null) {
              setState(() => _blockingLevel = value);
              final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
              await timerProvider.configureFocusSettings(blockingLevel: value);
            }
          } : null,
          items: FocusBlockingLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(_getBlockingLevelName(level)),
            );
          }).toList(),
        ),
      ),
      const Divider(height: 1),
      ListTile(
        title: const Text('Blocked Apps'),
        subtitle: const Text('View and manage blocked applications'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _focusModeEnabled ? () => _showBlockedAppsDialog() : null,
      ),
    ]);
  }

  Widget _buildAmbientSoundsSection() {
    final audioService = EnhancedAudioService();
    final profiles = audioService.getAvailableProfiles();
    final unlockedProfiles = profiles.where((p) => p.isUnlocked).toList();

    return _buildSettingsCard([
      ListTile(
        title: const Text('Ambient Sound'),
        subtitle: Text(_selectedSoundProfile?.name ?? 'None selected'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showSoundProfileDialog(unlockedProfiles),
      ),
      if (_selectedSoundProfile != null) ...[
        const Divider(height: 1),
        ListTile(
          title: const Text('Volume'),
          subtitle: Slider(
            value: audioService.volume,
            onChanged: (value) async {
              await audioService.setVolume(value);
              setState(() {});
            },
            activeColor: AppColors.primaryBlue,
          ),
        ),
      ],
    ]);
  }

  Widget _buildGamificationSection() {
    return Consumer<EnhancedTimerProvider>(
      builder: (context, timerProvider, child) {
        return _buildSettingsCard([
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              child: Text(
                '${timerProvider.currentLevel}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('Level ${timerProvider.currentLevel}'),
            subtitle: LinearProgressIndicator(
              value: timerProvider.levelProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            trailing: Text('${timerProvider.currentXP} XP'),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Badges & Achievements'),
            subtitle: Text('${timerProvider.earnedBadges.length} badges earned'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showBadgesDialog(),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Daily Challenges'),
            subtitle: Text('${timerProvider.activeChallenges.length} active challenges'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showChallengesDialog(),
          ),
        ]);
      },
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  String _getBlockingLevelName(FocusBlockingLevel level) {
    switch (level) {
      case FocusBlockingLevel.none:
        return 'None';
      case FocusBlockingLevel.gentle:
        return 'Gentle';
      case FocusBlockingLevel.moderate:
        return 'Moderate';
      case FocusBlockingLevel.strict:
        return 'Strict';
    }
  }

  String _getBlockingLevelDescription(FocusBlockingLevel level) {
    switch (level) {
      case FocusBlockingLevel.none:
        return 'No app blocking';
      case FocusBlockingLevel.gentle:
        return 'Gentle reminders when opening distracting apps';
      case FocusBlockingLevel.moderate:
        return 'Block apps with option to override';
      case FocusBlockingLevel.strict:
        return 'Strong blocking with difficult override';
    }
  }

  void _showSoundProfileDialog(List<FocusSoundProfile> profiles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Ambient Sound'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: profiles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.volume_off),
                  title: const Text('None'),
                  onTap: () async {
                    final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
                    await timerProvider.setAmbientSoundProfile(null);
                    if (mounted) {
                      setState(() => _selectedSoundProfile = null);
                      Navigator.pop(context);
                    }
                  },
                );
              }
              
              final profile = profiles[index - 1];
              return ListTile(
                leading: Text(profile.icon, style: const TextStyle(fontSize: 24)),
                title: Text(profile.name),
                subtitle: Text(profile.description),
                selected: _selectedSoundProfile?.id == profile.id,
                onTap: () async {
                  final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
                  await timerProvider.setAmbientSoundProfile(profile);
                  if (mounted) {
                    setState(() => _selectedSoundProfile = profile);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBlockedAppsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blocked Apps'),
        content: const SizedBox(
          width: double.maxFinite,
          child: Text('Common distracting apps like social media, games, and entertainment apps are automatically blocked during focus sessions.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBadgesDialog() {
    final gamification = FocusGamificationService();
    final badgeProgress = gamification.getBadgeProgress();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Badges & Achievements'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: badgeProgress.length,
            itemBuilder: (context, index) {
              final progress = badgeProgress[index];
              return ListTile(
                leading: Text(
                  progress.badge.icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: progress.isEarned ? null : Colors.grey,
                  ),
                ),
                title: Text(
                  progress.badge.name,
                  style: TextStyle(
                    color: progress.isEarned ? null : Colors.grey,
                    fontWeight: progress.isEarned ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(progress.badge.description),
                    if (!progress.isEarned)
                      LinearProgressIndicator(
                        value: progress.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                  ],
                ),
                trailing: progress.isEarned ? const Icon(Icons.check_circle, color: Colors.green) : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChallengesDialog() {
    final timerProvider = Provider.of<EnhancedTimerProvider>(context, listen: false);
    final challenges = timerProvider.activeChallenges;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Challenges'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: challenges.isEmpty
              ? const Center(child: Text('No active challenges'))
              : ListView.builder(
                  itemCount: challenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challenges[index];
                    return Card(
                      child: ListTile(
                        title: Text(challenge.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(challenge.description),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: challenge.progressPercentage,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${challenge.currentProgress}/${challenge.targetProgress} (+${challenge.bonusXP} XP)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: challenge.isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}
