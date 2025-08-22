import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
}
