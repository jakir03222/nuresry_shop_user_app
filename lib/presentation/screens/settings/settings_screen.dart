import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Settings
          _buildSectionTitle('Account Settings'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
              onTap: () {
                context.push('/edit-profile');
              },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              // Navigate to change password screen
            },
          ),
          const SizedBox(height: 24),
          // App Settings
          _buildSectionTitle('App Settings'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // Navigate to language selection
            },
          ),
          const SizedBox(height: 24),
          // Support
          _buildSectionTitle('Support'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & FAQ',
            subtitle: 'Get help and answers',
            onTap: () {
              // Navigate to help screen
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const SizedBox(height: 24),
          // Legal
          _buildSectionTitle('Legal'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: 'Terms & Conditions',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              // Navigate to terms screen
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // Navigate to privacy policy screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nursery Shop BD'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A modern nursery shop application for buying plants and gardening supplies.'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
