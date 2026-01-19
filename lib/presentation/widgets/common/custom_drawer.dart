import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFE3F2FD), // Light blue background
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section with Logo
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                children: [
                  // Logo - Green "N"
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App Name
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.home,
                    title: AppStrings.home,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    title: AppStrings.profile,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to profile
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.shopping_cart_outlined,
                    title: AppStrings.cart,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to cart
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.history,
                    title: 'Order History',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to order history
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Setting',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact Us',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to contact us
                    },
                  ),
                  const SizedBox(height: 16),
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOut();
              Navigator.pop(context);
              context.go('/get-started');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? AppColors.error : AppColors.textPrimary,
              size: 26,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLogout ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isLogout ? AppColors.error : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
