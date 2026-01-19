import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundWhite,
                      border: Border.all(
                        color: AppColors.textWhite,
                        width: 4,
                      ),
                    ),
                    child: user?.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              user!.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.primaryBlue,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primaryBlue,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'Guest User',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'guest@example.com',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.mobile ?? 'N/A',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Profile Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () {
                      context.push('/edit-profile');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      context.push('/settings');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    context,
                    icon: Icons.contact_support,
                    title: 'Contact Us',
                    onTap: () {
                      context.push('/contact-us');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildProfileOption(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
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
                color: isDestructive
                    ? AppColors.accentRed.withOpacity(0.1)
                    : AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? AppColors.accentRed
                    : AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? AppColors.accentRed
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Provider.of<AuthProvider>(context, listen: false).signOut();
                context.go('/get-started');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
