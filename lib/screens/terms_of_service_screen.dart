import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/responsive_utils.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                            Icons.description,
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Terms of Service',
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
                        'By using Focus Flow Timer, you agree to these terms. Please read them carefully.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Key Points Summary
              _buildSectionCard(
                context,
                'Key Points Summary',
                Icons.star,
                [
                  '• Free to use with optional premium features',
                  '• You must be 13+ years old to use the app',
                  '• Use the app responsibly and legally',
                  '• We can update features with reasonable notice',
                  '• You own your data and can export it anytime',
                  '• Disputes resolved through binding arbitration',
                ],
                cardColor: Colors.amber.withValues(alpha: 0.1),
                iconColor: Colors.amber.shade700,
              ),

              // Service Description
              _buildSectionCard(
                context,
                'What is Focus Flow Timer?',
                Icons.timer,
                [
                  'Focus Flow Timer is a professional Pomodoro timer app that provides:',
                  '',
                  '• Customizable Pomodoro timers with focus and break sessions',
                  '• Task management and organization features',
                  '• Analytics and productivity tracking',
                  '• Achievement system and progress monitoring',
                  '• Cloud synchronization across devices',
                  '• Offline functionality for core features',
                  '• Notification services for timer alerts',
                  '• Data export capabilities',
                  '• Optional leaderboard and social features',
                ],
              ),

              // Acceptable Use
              _buildSectionCard(
                context,
                'Acceptable Use',
                Icons.check_circle,
                [
                  'You MAY use the app for:',
                  '• Personal productivity and time management',
                  '• Educational and study purposes',
                  '• Professional work organization',
                  '• Legitimate productivity tracking',
                  '',
                  'You may NOT:',
                  '❌ Use the app for illegal activities',
                  '❌ Attempt to reverse engineer the app',
                  '❌ Use automated systems or bots',
                  '❌ Upload malicious content or viruses',
                  '❌ Interfere with app servers or services',
                  '❌ Harass or abuse other users',
                  '❌ Share inappropriate content',
                ],
                cardColor: Colors.green.withValues(alpha: 0.1),
                iconColor: Colors.green,
              ),

              // User Accounts
              _buildSectionCard(
                context,
                'User Accounts',
                Icons.account_circle,
                [
                  'Account Requirements:',
                  '• Must be 13+ years old (13-18 requires parent consent)',
                  '• Provide accurate information during registration',
                  '• Maintain confidentiality of account credentials',
                  '',
                  'Account Security:',
                  '• You are responsible for all account activities',
                  '• Notify us immediately of unauthorized access',
                  '• We may suspend accounts that violate these terms',
                  '',
                  'Offline Usage:',
                  '• Core features work without an account',
                  '• Account needed for cloud sync and advanced features',
                ],
              ),

              // Privacy and Data
              _buildSectionCard(
                context,
                'Your Privacy and Data',
                Icons.privacy_tip,
                [
                  'Data Collection:',
                  '• Timer sessions and productivity metrics',
                  '• Tasks and goals you create',
                  '• Usage analytics for app improvement',
                  '• Optional account information',
                  '',
                  'Your Rights:',
                  '• Export your data at any time',
                  '• Delete your account and data',
                  '• Control sharing and sync settings',
                  '• View detailed privacy policy',
                  '',
                  'Our Commitment:',
                  '• We never sell your personal data',
                  '• Data is encrypted and securely stored',
                  '• Transparent about data usage',
                ],
                cardColor: Colors.blue.withValues(alpha: 0.1),
                iconColor: Colors.blue,
              ),

              // Subscription Terms (If Applicable)
              _buildSectionCard(
                context,
                'Free Version & Premium Features',
                Icons.payment,
                [
                  'Free Version Includes:',
                  '• Core Pomodoro timer functionality',
                  '• Basic task management',
                  '• Local analytics and progress tracking',
                  '• Offline usage capability',
                  '',
                  'Premium Features (Future):',
                  '• Advanced analytics and detailed reporting',
                  '• Extended cloud storage and sync',
                  '• Priority customer support',
                  '• Additional customization options',
                  '• Advanced productivity insights',
                  '',
                  'Payment Processing:',
                  '• Handled by app store platforms (Apple/Google)',
                  '• Subscriptions auto-renew unless cancelled',
                  '• Refunds subject to app store policies',
                ],
              ),

              // Service Availability
              _buildSectionCard(
                context,
                'Service Availability',
                Icons.cloud_done,
                [
                  'Our Commitment:',
                  '• Strive for 99.9% uptime for cloud services',
                  '• Offline features always available',
                  '• Advance notice for scheduled maintenance',
                  '',
                  'Service Changes:',
                  '• We may modify features with reasonable notice',
                  '• Security and performance updates as needed',
                  '• 30 days notice for material changes to terms',
                  '',
                  'Third-Party Services:',
                  '• Firebase for authentication and data storage',
                  '• Analytics providers for app improvement',
                  '• Not responsible for third-party service issues',
                ],
              ),

              // Disclaimers and Limitations
              _buildSectionCard(
                context,
                'Important Disclaimers',
                Icons.warning,
                [
                  'Service Provided "AS IS":',
                  '• No warranties of any kind, express or implied',
                  '• No guarantee of uninterrupted service',
                  '• Use at your own risk and discretion',
                  '',
                  'Limitation of Liability:',
                  '• Not liable for indirect or consequential damages',
                  '• Maximum liability limited to \$100 or amount paid',
                  '• Not responsible for data loss (export regularly)',
                  '',
                  'Your Responsibility:',
                  '• Back up important data',
                  '• Use productivity tools responsibly',
                  '• Comply with all applicable laws',
                ],
                cardColor: Colors.orange.withValues(alpha: 0.1),
                iconColor: Colors.orange.shade700,
              ),

              // Termination
              _buildSectionCard(
                context,
                'Account Termination',
                Icons.exit_to_app,
                [
                  'You Can:',
                  '• Stop using the app at any time',
                  '• Delete your account through app settings',
                  '• Request complete data deletion',
                  '',
                  'We May Terminate Access If:',
                  '• Terms of service are violated',
                  '• Fraudulent or harmful activity detected',
                  '• Extended periods of inactivity',
                  '• Legal or safety requirements',
                  '',
                  'Upon Termination:',
                  '• Cloud access ends immediately',
                  '• Local data may remain on your device',
                  '• Account data deleted within 30 days',
                ],
              ),

              // Governing Law
              _buildSectionCard(
                context,
                'Legal Terms',
                Icons.gavel,
                [
                  'Governing Law:',
                  '• These terms governed by United States law',
                  '• Disputes resolved through binding arbitration',
                  '• Class action lawsuits are waived where permitted',
                  '• Small claims court available for qualifying disputes',
                  '',
                  'Changes to Terms:',
                  '• Material changes announced 30 days in advance',
                  '• Updates via app notifications or email',
                  '• Continued use constitutes acceptance',
                  '',
                  'Entire Agreement:',
                  '• These terms plus Privacy Policy are complete agreement',
                  '• Supersedes all previous agreements',
                ],
              ),

              // Contact Section
              _buildContactSection(context),

              // Footer
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Focus Flow Timer v1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 Focus Flow Team. All rights reserved.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: August 28, 2025',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

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
                    'Questions About Terms?',
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
                    'Legal Questions',
                    'legal@focusflow.app',
                    Icons.gavel,
                    () => _launchEmail('legal@focusflow.app', 'Terms of Service Question'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactButton(
                    context,
                    'General Support',
                    'support@focusflow.app',
                    Icons.help,
                    () => _launchEmail('support@focusflow.app', 'General Support'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactButton(
                    context,
                    'Business Inquiries',
                    'business@focusflow.app',
                    Icons.business,
                    () => _launchEmail('business@focusflow.app', 'Business Inquiry'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mailing Address:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Focus Flow Team\n123 Productivity Lane\nFocus City, FC 12345\nUnited States',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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