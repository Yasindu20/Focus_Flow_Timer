import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/enhanced_sound_selector.dart';
import '../core/utils/responsive_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? (isSmallMobile ? 12 : 16) : 20),
              child: Column(
                children: [
                  // Appearance section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? (isSmallMobile ? 12 : 16) : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return SwitchListTile(
                                title: const Text('Dark Mode'),
                                subtitle: const Text(
                                  'Switch between light and dark themes',
                                ),
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.setDarkMode(value);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Soundscape section
                  const EnhancedSoundSelector(),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // App info section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? (isSmallMobile ? 12 : 16) : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          const ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('Focus Flow Timer'),
                            subtitle: Text('Free Version - Basic Pomodoro Timer'),
                          ),
                          const ListTile(
                            leading: Icon(Icons.timer),
                            title: Text('Features'),
                            subtitle: Text('Timer, Tasks, Background Sounds, Analytics'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Help section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? (isSmallMobile ? 12 : 16) : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help & Support',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('How to Use'),
                            subtitle: const Text('Learn about Focus Flow features'),
                            onTap: () => _showHelpDialog(context),
                          ),
                          const ListTile(
                            leading: Icon(Icons.feedback),
                            title: Text('Feedback'),
                            subtitle: Text('Share your thoughts and suggestions'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Add bottom padding to prevent overflow
                  SizedBox(height: isMobile ? 20 : 0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Focus Flow'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * (isSmallScreen ? 0.6 : 0.7),
            maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.9 : 0.8),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🍅 Pomodoro Technique:'),
                const Text('• Work for 25 minutes'),
                const Text('• Take a 5-minute break'),
                const Text('• Repeat 4 times, then take a long break'),
                SizedBox(height: isSmallScreen ? 8 : 12),
                const Text('📝 Tasks:'),
                const Text('• Add tasks in the Tasks tab'),
                const Text('• Select a task before starting timer'),
                const Text('• Track your progress'),
                SizedBox(height: isSmallScreen ? 8 : 12),
                const Text('🎵 Sounds:'),
                const Text('• Choose background sounds for focus'),
                const Text('• Adjust volume as needed'),
                SizedBox(height: isSmallScreen ? 8 : 12),
                const Text('📊 Analytics:'),
                const Text('• View your productivity statistics'),
                const Text('• Track completion rates and time spent'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}