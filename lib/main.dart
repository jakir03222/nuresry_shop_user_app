import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/sync_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/favorite_provider.dart'; 

import 'presentation/providers/address_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/contact_provider.dart';
import 'presentation/providers/coupon_provider.dart';
import 'presentation/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database for offline cache
  try {
    await DatabaseService.initialize();
    debugPrint('[main] SQLite database initialized');
  } catch (e) {
    debugPrint('[main] Database initialization failed: $e');
    // Continue app startup even if database fails
  }
  
  
  // Initialize Sync Service for online/offline data synchronization
  try {
    await SyncService().initialize();
    debugPrint('[main] SyncService initialized');
  } catch (e) {
    debugPrint('[main] SyncService initialization failed: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final authProvider = AuthProvider();
            // Check authentication status on app start
            authProvider.checkAuthStatus();
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final cartProvider = CartProvider();
            cartProvider.loadCartFromCache(); // Preload from cache for instant display
            return cartProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
      ],
      child: MaterialApp.router(
        title: 'Nursery Shop BD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
