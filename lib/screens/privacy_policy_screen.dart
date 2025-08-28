import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/responsive_utils.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Card(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.privacy_tip,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy Policy for Focus Flow Timer',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Effective Date: August 28, 2025',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We are committed to protecting your privacy and being transparent about how we collect, use, and share your information.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Quick Summary Section
              _buildSectionCard(
                context,
                'Quick Summary',
                Icons.info_outline,
                [
                  '• We only collect data necessary for app functionality',
                  '• We never sell your personal information',
                  '• You can export or delete your data at any time',
                  '• We use Firebase for secure data storage and analytics',
                  '• Your timer sessions and tasks are private to you',
                ],
              ),

              // Information We Collect
              _buildSectionCard(
                context,
                'Information We Collect',
                Icons.data_usage,
                [
                  'Account Information:',
                  '• Email address (for account creation)',
                  '• Display name (optional)',
                  '• Encrypted password',
                  '',
                  'App Usage Data:',
                  '• Timer sessions and completion status',
                  '• Tasks and categories you create',
                  '• Productivity goals and preferences',
                  '• App settings and customizations',
                  '',
                  'Analytics Data:',
                  '• App usage patterns (anonymized)',
                  '• Performance metrics and crash reports',
                  '• Device type and OS version (anonymized)',
                ],
              ),

              // What We DON'T Collect
              _buildSectionCard(
                context,
                'What We DON\'T Collect',
                Icons.block,
                [
                  '❌ Location data',
                  '❌ Contact lists or address books',
                  '❌ Camera or microphone access',
                  '❌ Personal files or documents',
                  '❌ Payment information',
                  '❌ Browsing history from other apps',
                  '❌ Social media profiles',
                ],
                cardColor: Colors.green.withValues(alpha: 0.1),
                iconColor: Colors.green,
              ),

              // How We Use Your Information
              _buildSectionCard(
                context,
                'How We Use Your Information',
                Icons.security,
                [
                  'App Functionality:',
                  '• Provide timer and productivity features',
                  '• Save your tasks and preferences',
                  '• Sync data across your devices',
                  '• Display personalized analytics',
                  '',
                  'Account Management:',
                  '• Create and maintain your account',
                  '• Secure authentication',
                  '• Data synchronization and backup',
                  '',
                  'App Improvement:',
                  '• Analyze usage to improve features',
                  '• Fix bugs and performance issues',
                  '• Develop new functionality',
                ],
              ),

              // Your Rights
              _buildSectionCard(
                context,
                'Your Privacy Rights',
                Icons.account_circle,
                [
                  'GDPR Rights (EU Residents):',
                  '• Access your personal data',
                  '• Correct inaccurate information',
                  '• Request data deletion',
                  '• Export your data',
                  '• Limit data processing',
                  '',
                  'CCPA Rights (California Residents):',
                  '• Know what data we collect',
                  '• Request data deletion',
                  '• Opt-out of data sales (we don\'t sell data)',
                  '',
                  'Exercise Your Rights:',
                  '• Use in-app controls in Settings',
                  '• Contact us at privacy@focusflow.app',
                ],
              ),

              // Data Security
              _buildSectionCard(
                context,
                'Data Security',
                Icons.lock,
                [
                  'Security Measures:',
                  '• All data encrypted in transit (TLS)',
                  '• Secure Firebase Authentication',
                  '• Strict access controls',
                  '• Regular security audits',
                  '• Code obfuscation protection',
                  '',
                  'Data Breach Response:',
                  '• User notification within 72 hours',
                  '• Immediate breach containment',
                  '• Authority reporting as required',
                ],
                cardColor: Colors.blue.withValues(alpha: 0.1),
                iconColor: Colors.blue,
              ),

              // Third-Party Services
              _buildSectionCard(
                context,
                'Third-Party Services',
                Icons.cloud,
                [
                  'Google Firebase:',
                  '• Authentication and database',
                  '• Privacy Policy: policies.google.com/privacy',
                  '',
                  'Google Analytics for Firebase:',
                  '• Usage analytics (anonymized)',
                  '• Crash reporting',
                  '• You can opt out in app settings',
                ],
              ),

              // Data Retention
              _buildSectionCard(
                context,
                'Data Retention',
                Icons.schedule,
                [
                  '• Active accounts: Data kept while account is active',
                  '• Inactive accounts: Auto-deleted after 3 years',
                  '• Deleted accounts: Permanently removed within 30 days',
                  '• Analytics data: Kept for up to 2 years (anonymized)',
                  '• Temporary files: Regularly cleared automatically',
                ],
              ),

              // Contact Information
              _buildContactSection(context),

              // Bottom padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<String> content, {
    Color? cardColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final item in content) 
                if (item.isEmpty)
                  const SizedBox(height: 8)
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item,
                      style: (item.endsWith(':') && !item.startsWith('•') && !item.startsWith('❌'))
                          ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_support,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Contact Us',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Contact buttons
              Column(
                children: [
                  _buildContactButton(
                    context,
                    'Privacy Questions',
                    'privacy@focusflow.app',
                    Icons.privacy_tip,
                    () => _launchEmail('privacy@focusflow.app', 'Privacy Question'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactButton(
                    context,
                    'General Support',
                    'support@focusflow.app',
                    Icons.help,
                    () => _launchEmail('support@focusflow.app', 'Support Request'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactButton(
                    context,
                    'Data Protection Officer',
                    'dpo@focusflow.app',
                    Icons.admin_panel_settings,
                    () => _launchEmail('dpo@focusflow.app', 'Data Protection Inquiry'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Text(
                'Response Time: We aim to respond within 48 hours',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context,
    String title,
    String email,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}