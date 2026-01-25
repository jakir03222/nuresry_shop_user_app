import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
        // Load wishlist when profile screen opens
        final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
        favoriteProvider.loadWishlist();
      }
    });
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => _isLoadingProfile = true);
    try {
      await authProvider.loadProfile();
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
                    
                    return Column(
                      children: [
                        // Profile Header (API data)
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
                              // Profile Picture
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
                                child: ClipOval(
                                  child: user?.profileImage != null &&
                                          user!.profileImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: user.profileImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          placeholder: (context, url) => Container(
                                            width: 100,
                                            height: 100,
                                            color: AppColors.backgroundWhite,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.primaryBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 100,
                                            height: 100,
                                            color: AppColors.backgroundWhite,
                                            child: const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          color: AppColors.backgroundWhite,
                                          child: const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name
                              Text(
                                user?.name ?? 'Guest User',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Email
                              Text(
                                user?.email ?? 'guest@example.com',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                ),
                              ),
                              // Mobile (if available)
                              if (user?.mobile != null &&
                                  user!.mobile!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.mobile!,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              // Role and Status badges
                              if (user != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.lerp(
                                          AppColors.textWhite,
                                          Colors.transparent,
                                          0.8,
                                        )!,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.role.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.lerp(
                                          user.status == 'active'
                                              ? AppColors.success
                                              : AppColors.error,
                                          Colors.transparent,
                                          0.8,
                                        )!,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.status.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
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
                              Consumer<FavoriteProvider>(
                                builder: (context, favoriteProvider, _) {
                                  return _buildProfileOption(
                                    context,
                                    icon: Icons.favorite,
                                    title: 'My Wishlist',
                                    onTap: () => context.push('/wishlist'),
                                    badge: favoriteProvider.wishlistCount > 0
                                        ? favoriteProvider.wishlistCount.toString()
                                        : null,
                                  );
                                },
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
