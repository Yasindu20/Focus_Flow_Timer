import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/enhanced_sound_selector.dart';
import '../services/soundscape_download_service.dart';

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

          // Storage management
          ChangeNotifierProvider(
            create: (_) => SoundscapeDownloadService(),
            child: Consumer<SoundscapeDownloadService>(
              builder: (context, downloadService, child) {
                return FutureBuilder<int>(
                  future: downloadService.getTotalStorageUsed(),
                  builder: (context, snapshot) {
                    final storageUsed = snapshot.data ?? 0;
                    
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Storage Management',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.storage),
                              title: const Text('Downloaded Soundscapes'),
                              subtitle: Text(
                                'Using ${SoundscapeDownloadService.formatBytes(storageUsed)}',
                              ),
                              trailing: TextButton(
                                onPressed: storageUsed > 0 
                                    ? () => _showStorageManagement(context, downloadService)
                                    : null,
                                child: const Text('Manage'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // About section
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
                    leading: Icon(Icons.info),
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // Implement privacy policy navigation
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.gavel),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      // Implement terms of service navigation
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Support section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & FAQ'),
                    onTap: () {
                      // Implement help navigation
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Contact Support'),
                    onTap: () {
                      // Implement contact support
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Rate App'),
                    onTap: () {
                      // Implement app rating
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStorageManagement(BuildContext context, SoundscapeDownloadService downloadService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Manage your downloaded soundscape files'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear All Downloads'),
              subtitle: const Text('Free up storage space'),
              onTap: () async {
                await downloadService.deleteAllTracks();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All downloads cleared')),
                );
              },
            ),
          ],
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
