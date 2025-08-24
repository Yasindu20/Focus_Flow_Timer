import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/enhanced_sound_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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

          const SizedBox(height: 16),

          // Soundscape section
          const EnhancedSoundSelector(),

          const SizedBox(height: 16),

          // App info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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

          const SizedBox(height: 16),

          // Help section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Support',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use Focus Flow'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🍅 Pomodoro Technique:'),
              Text('• Work for 25 minutes'),
              Text('• Take a 5-minute break'),
              Text('• Repeat 4 times, then take a long break'),
              SizedBox(height: 12),
              Text('📝 Tasks:'),
              Text('• Add tasks in the Tasks tab'),
              Text('• Select a task before starting timer'),
              Text('• Track your progress'),
              SizedBox(height: 12),
              Text('🎵 Sounds:'),
              Text('• Choose background sounds for focus'),
              Text('• Adjust volume as needed'),
              SizedBox(height: 12),
              Text('📊 Analytics:'),
              Text('• View your productivity statistics'),
              Text('• Track completion rates and time spent'),
            ],
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