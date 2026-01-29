import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/cart_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    // When Profile tab is selected / screen opens: call GET {{baseUrl}}/users/profile and show API data in UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  /// Calls GET {{baseUrl}}/users/profile and updates UI with response data (name, emailOrPhone, avatarId.imageUrl/profilePicture, role, status).
  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }
    if (mounted) setState(() => _isLoadingProfile = true);
    try {
      await authProvider.loadProfile(forceRefresh: true);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.user;
                    
                    // Show error if profile failed to load
                    if (authProvider.errorMessage != null && user == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load profile',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                authProvider.errorMessage ?? 'Unknown error',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // API response data: name, emailOrPhone, profilePicture | avatarId.imageUrl, role, status
                    return Column(
                      children: [
                        // Profile Header – GET {{baseUrl}}/users/profile data
                    
                    
                    
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildProfileOption(
                                context,
                                icon: Icons.edit,
                                title: 'Edit Profile',
                                onTap: () => context.push('/edit-profile'),
                              ),
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.settings,
                                title: 'Settings',
                                onTap: () => context.push('/settings'),
                              ),
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.confirmation_number_outlined,
                                title: 'My Coupons',
                                onTap: () => context.push('/coupons'),
                              ),
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.shopping_bag_outlined,
                                title: 'Order History',
                                onTap: () => context.push('/order-history'),
                              ),
                         
                            
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.favorite,
                                title: 'My Wishlist',
                                onTap: () => context.push('/wishlist'),
                              ),
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.contact_support,
                                title: 'Contact Us',
                                onTap: () => context.push('/contact-us'),
                              ),
                              const SizedBox(height: 12),
                              _buildProfileOption(
                                context,
                                icon: Icons.logout,
                                title: 'Logout',
                                onTap: () => _showLogoutDialog(context),
                                isDestructive: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/cart');
              break;
            case 2:
              break;
          }
        },
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: AppStrings.cart,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    String? badge,
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
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
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
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Clear all providers
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
                
                // Clear all cached data and storage
                await StorageService.clearAll();
                
                // Clear all provider states
                await authProvider.signOut();
                cartProvider.clearCartData();
                favoriteProvider.clearAllData();
                
                // Navigate to splash screen (replaces current route)
                if (context.mounted) {
                  context.go('/splash');
                }
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
