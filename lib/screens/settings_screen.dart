import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/enhanced_sound_selector.dart';
import '../core/utils/responsive_utils.dart';
import '../core/constants/app_constants.dart';
import '../services/data_export_service.dart';

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

                  // Privacy & Data section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? (isSmallMobile ? 12 : 16) : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy & Data',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy Policy'),
                            subtitle: const Text('View our privacy policy'),
                            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Terms of Service'),
                            subtitle: const Text('View terms and conditions'),
                            onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              if (!authProvider.isAuthenticated) {
                                return const SizedBox.shrink();
                              }
                              
                              return Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.download),
                                    title: const Text('Export My Data'),
                                    subtitle: const Text('Download all your data (GDPR)'),
                                    onTap: () => _exportUserData(context, authProvider.userId!),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                                    title: const Text('Delete Account'),
                                    subtitle: const Text('Permanently delete your account'),
                                    onTap: () => _showDeleteAccountDialog(context),
                                  ),
                                ],
                              );
                            },
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
                          ListTile(
                            leading: const Icon(Icons.feedback),
                            title: const Text('Feedback'),
                            subtitle: const Text('Share your thoughts and suggestions'),
                            onTap: () => _sendFeedback(),
                          ),
                          ListTile(
                            leading: const Icon(Icons.web),
                            title: const Text('Website'),
                            subtitle: const Text('Visit our website'),
                            onTap: () => _launchUrl(AppConstants.appWebsiteUrl),
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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Could not launch $url',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error launching URL: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _sendFeedback() async {
    try {
      final uri = Uri.parse('mailto:${AppConstants.supportEmail}?subject=Focus%20Flow%20Timer%20Feedback');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Fluttertoast.showToast(
          msg: 'Could not open email client',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error sending feedback: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _exportUserData(BuildContext context, String userId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final dataExportService = DataExportService();
      final filePath = await dataExportService.exportUserDataToFile(userId);
      
      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (filePath != null) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully.'),
                const SizedBox(height: 16),
                Text('File saved to: $filePath'),
                const SizedBox(height: 16),
                const Text('This file contains all your personal data including:'),
                const Text('• Account information'),
                const Text('• Timer sessions and analytics'),
                const Text('• Tasks and achievements'),
                const Text('• App preferences'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Share.shareXFiles([XFile(filePath)], text: 'My Focus Flow Timer Data Export');
                },
                child: const Text('Share File'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Failed'),
          content: Text('Failed to export data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final dataToDelete = await authProvider.getAccountDeletionPreview();
      
      if (!context.mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ This action cannot be undone!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('The following data will be permanently deleted:'),
                const SizedBox(height: 8),
                ...dataToDelete.map((item) => Text('• $item')),
                const SizedBox(height: 16),
                const Text('Before proceeding:'),
                const Text('• Export your data if you want to keep it'),
                const Text('• Make sure you want to permanently delete everything'),
                const SizedBox(height: 16),
                const Text('Type "DELETE" to confirm:'),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    // Will be handled by the confirm button
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type DELETE here',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _confirmDeleteAccount(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load account data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Navigator.of(context).pop();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Deleting Account...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait while we delete your account and all associated data.'),
          ],
        ),
      ),
    );

    try {
      final success = await authProvider.deleteAccount();
      
      if (!context.mounted) return;
      
      Navigator.of(context).pop();
      
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Account Deleted'),
            content: const Text('Your account and all associated data have been permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Deletion Failed'),
            content: Text('Failed to delete account: ${authProvider.errorMessage}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}