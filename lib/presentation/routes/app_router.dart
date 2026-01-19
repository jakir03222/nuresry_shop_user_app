import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/auth/get_started_screen.dart';
import '../screens/auth/create_account_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/product/flash_sale_detail_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/all_flash_sales_screen.dart';
import '../screens/category/all_categories_screen.dart';
import '../screens/category/category_products_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/contact/contact_us_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../providers/product_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/get-started',
    routes: [
      GoRoute(
        path: '/get-started',
        name: 'get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/create-account',
        name: 'create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        name: 'contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/all-categories',
        name: 'all-categories',
        builder: (context, state) => const AllCategoriesScreen(),
      ),
      GoRoute(
        path: '/category-products/:categoryId',
        name: 'category-products',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          return CategoryProductsScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/all-flash-sales',
        name: 'all-flash-sales',
        builder: (context, state) => const AllFlashSalesScreen(),
      ),
      GoRoute(
        path: '/product-detail/:id',
        name: 'product-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return Builder(
            builder: (context) {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final product = productProvider.getProductById(id);
              if (product == null) {
                return const Scaffold(
                  body: Center(child: Text('Product not found')),
                );
              }
              return ProductDetailScreen(product: product);
            },
          );
        },
      ),
      GoRoute(
        path: '/flash-sale/:id',
        name: 'flash-sale-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return Builder(
            builder: (context) {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              final product = productProvider.getProductById(id);
              if (product == null) {
                return const Scaffold(
                  body: Center(child: Text('Product not found')),
                );
              }
              return FlashSaleDetailScreen(product: product);
            },
          );
        },
      ),
    ],
  );
}
