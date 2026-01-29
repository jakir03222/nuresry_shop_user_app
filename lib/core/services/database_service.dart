import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'nursery_shop.db';
  static const int _databaseVersion = 3;

  // Table names
  static const String tableProducts = 'products';
  static const String tableCategories = 'categories';
  static const String tableCarousels = 'carousels';
  static const String tableFlashSales = 'flash_sales';
  static const String tableCart = 'cart';
  static const String tableCartItems = 'cart_items';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tableAddresses = 'addresses';
  static const String tableCoupons = 'coupons';
  static const String tableWishlist = 'wishlist';
  static const String tableUser = 'user_profile';
  static const String tableCacheMeta = 'cache_meta';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('[DatabaseService] Error initializing database: $e');
      rethrow;
    }
  }

  // Initialize database on app start
  static Future<void> initialize() async {
    try {
      await database;
      debugPrint('[DatabaseService] Database initialized successfully');
    } catch (e) {
      debugPrint('[DatabaseService] Failed to initialize database: $e');
      // Don't throw - app should still work without cache
    }
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  static Future<void> _onCreate(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT,
        description TEXT,
        image TEXT,
        images TEXT,
        price REAL NOT NULL,
        discount REAL DEFAULT 0,
        quantity INTEGER DEFAULT 0,
        isAvailable INTEGER DEFAULT 1,
        isFeatured INTEGER DEFAULT 0,
        brand TEXT,
        categoryId TEXT,
        tags TEXT,
        ratingAverage REAL DEFAULT 0,
        ratingCount INTEGER DEFAULT 0,
        flashSaleId TEXT,
        data TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image TEXT,
        isActive INTEGER DEFAULT 1,
        displayOrder INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Carousels table
    await db.execute('''
      CREATE TABLE $tableCarousels (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        image TEXT,
        link TEXT,
        isActive INTEGER DEFAULT 1,
        displayOrder INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Flash Sales table
    await db.execute('''
      CREATE TABLE $tableFlashSales (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        startDate TEXT,
        endDate TEXT,
        discountPercentage REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        displayOrder INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Cart table
    await db.execute('''
      CREATE TABLE $tableCart (
        id TEXT PRIMARY KEY,
        userId TEXT,
        subtotal REAL DEFAULT 0,
        total REAL DEFAULT 0,
        totalItems INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Cart Items table
    await db.execute('''
      CREATE TABLE $tableCartItems (
        id TEXT PRIMARY KEY,
        cartId TEXT,
        productId TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        price REAL NOT NULL,
        total REAL NOT NULL,
        productData TEXT,
        FOREIGN KEY (cartId) REFERENCES $tableCart(id) ON DELETE CASCADE
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE $tableOrders (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        userId TEXT,
        orderStatus TEXT,
        paymentStatus TEXT,
        paymentMethod TEXT,
        subtotal REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        shippingCost REAL DEFAULT 0,
        total REAL DEFAULT 0,
        discountAmount REAL DEFAULT 0,
        shippingAddress TEXT,
        billingAddress TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Order Items table
    await db.execute('''
      CREATE TABLE $tableOrderItems (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        productId TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total REAL NOT NULL,
        productData TEXT,
        FOREIGN KEY (orderId) REFERENCES $tableOrders(id) ON DELETE CASCADE
      )
    ''');

    // Addresses table
    await db.execute('''
      CREATE TABLE $tableAddresses (
        id TEXT PRIMARY KEY,
        userId TEXT,
        fullName TEXT NOT NULL,
        phone TEXT,
        street TEXT,
        city TEXT,
        postalCode TEXT,
        country TEXT,
        isDefault INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Coupons table
    await db.execute('''
      CREATE TABLE $tableCoupons (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        description TEXT,
        discountType TEXT,
        discountValue REAL DEFAULT 0,
        minPurchase REAL DEFAULT 0,
        maxDiscount REAL,
        validFrom TEXT,
        validUntil TEXT,
        isActive INTEGER DEFAULT 1,
        usageLimit INTEGER,
        usedCount INTEGER DEFAULT 0,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Wishlist table
    await db.execute('''
      CREATE TABLE $tableWishlist (
        id TEXT PRIMARY KEY,
        userId TEXT,
        productId TEXT NOT NULL,
        productData TEXT,
        createdAt TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // User Profile table
    await db.execute('''
      CREATE TABLE $tableUser (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT DEFAULT 'user',
        isEmailVerified INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        isDeleted INTEGER DEFAULT 0,
        mobile TEXT,
        profileImage TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        data TEXT,
        lastSynced INTEGER DEFAULT 0
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE $tableCacheMeta (
        key TEXT PRIMARY KEY,
        value TEXT,
        lastUpdated INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_category ON $tableProducts(categoryId)');
    await db.execute('CREATE INDEX idx_products_flashSale ON $tableProducts(flashSaleId)');
    await db.execute('CREATE INDEX idx_cart_items_cart ON $tableCartItems(cartId)');
    await db.execute('CREATE INDEX idx_order_items_order ON $tableOrderItems(orderId)');
    await db.execute('CREATE INDEX idx_wishlist_user ON $tableWishlist(userId)');
  }

  // Upgrade database
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // If upgrading from version 1, drop and recreate tables with correct column names
    if (oldVersion < 2) {
      debugPrint('[DatabaseService] Upgrading database from version $oldVersion to $newVersion');
      try {
        // Drop old tables that have the 'order' column issue
        await db.execute('DROP TABLE IF EXISTS $tableCategories');
        await db.execute('DROP TABLE IF EXISTS $tableCarousels');
        await db.execute('DROP TABLE IF EXISTS $tableFlashSales');
        
        // Recreate only the affected tables with correct schema
        // Categories
        await db.execute('''
          CREATE TABLE $tableCategories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            image TEXT,
            isActive INTEGER DEFAULT 1,
            displayOrder INTEGER DEFAULT 0,
            data TEXT,
            lastSynced INTEGER DEFAULT 0
          )
        ''');
        
        // Carousels
        await db.execute('''
          CREATE TABLE $tableCarousels (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            image TEXT,
            link TEXT,
            isActive INTEGER DEFAULT 1,
            displayOrder INTEGER DEFAULT 0,
            data TEXT,
            lastSynced INTEGER DEFAULT 0
          )
        ''');
        
        // Flash Sales
        await db.execute('''
          CREATE TABLE $tableFlashSales (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            startDate TEXT,
            endDate TEXT,
            discountPercentage REAL DEFAULT 0,
            isActive INTEGER DEFAULT 1,
            displayOrder INTEGER DEFAULT 0,
            data TEXT,
            lastSynced INTEGER DEFAULT 0
          )
        ''');
        
        // Recreate indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON $tableProducts(categoryId)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_products_flashSale ON $tableProducts(flashSaleId)');
        
        debugPrint('[DatabaseService] Database upgrade completed');
      } catch (e) {
        debugPrint('[DatabaseService] Error during upgrade: $e');
        rethrow;
      }
    }
    
    // If upgrading from version 2, add user profile table
    if (oldVersion < 3) {
      debugPrint('[DatabaseService] Upgrading database from version $oldVersion to $newVersion');
      try {
        // Create user profile table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableUser (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            role TEXT DEFAULT 'user',
            isEmailVerified INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            isDeleted INTEGER DEFAULT 0,
            mobile TEXT,
            profileImage TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            data TEXT,
            lastSynced INTEGER DEFAULT 0
          )
        ''');
        debugPrint('[DatabaseService] User profile table created');
      } catch (e) {
        debugPrint('[DatabaseService] Error creating user table: $e');
        rethrow;
      }
    }
  }

  // Get current timestamp
  static int _getCurrentTimestamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  // ========== Products ==========
  static Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var product in products) {
      batch.insert(
        tableProducts,
        {
          'id': product['_id'] ?? product['id'] ?? '',
          'name': product['name'] ?? '',
          'sku': product['sku'],
          'description': product['description'],
          'image': product['image'],
          'images': product['images'] != null ? jsonEncode(product['images']) : null,
          'price': (product['price'] ?? 0).toDouble(),
          'discount': (product['discount'] ?? 0).toDouble(),
          'quantity': product['quantity'] ?? 0,
          'isAvailable': (product['isAvailable'] ?? true) ? 1 : 0,
          'isFeatured': (product['isFeatured'] ?? false) ? 1 : 0,
          'brand': product['brand'],
          'categoryId': product['categoryId'],
          'tags': product['tags'] != null ? jsonEncode(product['tags']) : null,
          'ratingAverage': (product['ratingAverage'] ?? 0).toDouble(),
          'ratingCount': product['ratingCount'] ?? 0,
          'flashSaleId': product['flashSaleId'],
          'data': jsonEncode(product),
          'createdAt': product['createdAt'],
          'updatedAt': product['updatedAt'],
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${products.length} products to cache');
  }

  static Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? flashSaleId,
  }) async {
    try {
      final db = await database;
      String query = 'SELECT * FROM $tableProducts WHERE 1=1';
      List<dynamic> args = [];

      if (categoryId != null) {
        query += ' AND categoryId = ?';
        args.add(categoryId);
      }

      if (flashSaleId != null) {
        query += ' AND flashSaleId = ?';
        args.add(flashSaleId);
      }

      query += ' ORDER BY lastSynced DESC';

      final results = await db.rawQuery(query, args);
      return results.map((row) {
        try {
          final dataString = row['data'] as String?;
          if (dataString == null || dataString.isEmpty) {
            // Fallback: reconstruct from row data
            return {
              '_id': row['id'] as String? ?? '',
              'name': row['name'] as String? ?? '',
              'price': row['price'] as double? ?? 0.0,
              'image': row['image'] as String? ?? '',
              'categoryId': row['categoryId'] as String?,
              'flashSaleId': row['flashSaleId'] as String?,
            };
          }
          final decoded = jsonDecode(dataString);
          return decoded as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[DatabaseService] Error decoding product: $e');
          // Fallback: reconstruct from row data
          return {
            '_id': row['id'] as String? ?? '',
            'name': row['name'] as String? ?? '',
            'price': row['price'] as double? ?? 0.0,
            'image': row['image'] as String? ?? '',
            'categoryId': row['categoryId'] as String?,
            'flashSaleId': row['flashSaleId'] as String?,
          };
        }
      }).toList();
    } catch (e) {
      debugPrint('[DatabaseService] Error getting products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        tableProducts,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;

      try {
        final dataString = result.first['data'] as String?;
        if (dataString == null || dataString.isEmpty) {
          // Fallback: reconstruct from row data
          final row = result.first;
          return {
            '_id': row['id'] as String? ?? '',
            'name': row['name'] as String? ?? '',
            'price': row['price'] as double? ?? 0.0,
            'image': row['image'] as String? ?? '',
            'categoryId': row['categoryId'] as String?,
            'flashSaleId': row['flashSaleId'] as String?,
          };
        }
        final decoded = jsonDecode(dataString);
        return decoded as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[DatabaseService] Error decoding product by id: $e');
        // Fallback: reconstruct from row data
        final row = result.first;
        return {
          '_id': row['id'] as String? ?? '',
          'name': row['name'] as String? ?? '',
          'price': row['price'] as double? ?? 0.0,
          'image': row['image'] as String? ?? '',
          'categoryId': row['categoryId'] as String?,
          'flashSaleId': row['flashSaleId'] as String?,
        };
      }
    } catch (e) {
      debugPrint('[DatabaseService] Error getting product by id: $e');
      return null;
    }
  }

  // ========== Categories ==========
  static Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var category in categories) {
      batch.insert(
        tableCategories,
        {
          'id': category['_id'] ?? category['id'] ?? '',
          'name': category['name'] ?? '',
          'description': category['description'],
          'image': category['image'],
          'isActive': (category['isActive'] ?? true) ? 1 : 0,
          'displayOrder': category['order'] ?? category['displayOrder'] ?? 0,
          'data': jsonEncode(category),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${categories.length} categories to cache');
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final db = await database;
      final results = await db.query(
        tableCategories,
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'displayOrder ASC',
      );

      return results.map((row) {
        try {
          final dataString = row['data'] as String?;
          if (dataString == null || dataString.isEmpty) {
            // Fallback: reconstruct from row data
            return {
              '_id': row['id'] as String? ?? '',
              'name': row['name'] as String? ?? '',
              'title': row['name'] as String? ?? '',
              'image': row['image'] as String? ?? '',
              'description': row['description'] as String?,
              'isActive': (row['isActive'] as int? ?? 1) == 1,
              'order': row['displayOrder'] as int? ?? 0,
            };
          }
          final decoded = jsonDecode(dataString);
          return decoded as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[DatabaseService] Error decoding category: $e');
          // Fallback: reconstruct from row data
          return {
            '_id': row['id'] as String? ?? '',
            'name': row['name'] as String? ?? '',
            'title': row['name'] as String? ?? '',
            'image': row['image'] as String? ?? '',
            'description': row['description'] as String?,
            'isActive': (row['isActive'] as int? ?? 1) == 1,
            'order': row['displayOrder'] as int? ?? 0,
          };
        }
      }).toList();
    } catch (e) {
      debugPrint('[DatabaseService] Error getting categories: $e');
      return [];
    }
  }

  // ========== Carousels ==========
  static Future<void> saveCarousels(List<Map<String, dynamic>> carousels) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var carousel in carousels) {
      batch.insert(
        tableCarousels,
        {
          'id': carousel['_id'] ?? carousel['id'] ?? '',
          'title': carousel['title'] ?? '',
          'description': carousel['description'],
          'image': carousel['image'],
          'link': carousel['link'],
          'isActive': (carousel['isActive'] ?? true) ? 1 : 0,
          'displayOrder': carousel['order'] ?? carousel['displayOrder'] ?? 0,
          'data': jsonEncode(carousel),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${carousels.length} carousels to cache');
  }

  static Future<List<Map<String, dynamic>>> getCarousels() async {
    final db = await database;
    final results = await db.query(
      tableCarousels,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'displayOrder ASC',
    );

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ========== Flash Sales ==========
  static Future<void> saveFlashSales(List<Map<String, dynamic>> flashSales) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var flashSale in flashSales) {
      batch.insert(
        tableFlashSales,
        {
          'id': flashSale['_id'] ?? flashSale['id'] ?? '',
          'name': flashSale['name'] ?? '',
          'description': flashSale['description'],
          'startDate': flashSale['startDate'],
          'endDate': flashSale['endDate'],
          'discountPercentage': (flashSale['discountPercentage'] ?? 0).toDouble(),
          'isActive': (flashSale['isActive'] ?? true) ? 1 : 0,
          'displayOrder': flashSale['order'] ?? flashSale['displayOrder'] ?? 0,
          'data': jsonEncode(flashSale),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${flashSales.length} flash sales to cache');
  }

  static Future<List<Map<String, dynamic>>> getFlashSales() async {
    final db = await database;
    final results = await db.query(
      tableFlashSales,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'displayOrder ASC',
    );

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ========== Cart ==========
  static Future<void> saveCart(Map<String, dynamic> cartData) async {
    final db = await database;
    final timestamp = _getCurrentTimestamp();

    // Delete old cart items
    await db.delete(tableCartItems);

    // Save cart
    await db.insert(
      tableCart,
      {
        'id': cartData['_id'] ?? cartData['id'] ?? '',
        'userId': cartData['userId'],
        'subtotal': (cartData['subtotal'] ?? 0).toDouble(),
        'total': (cartData['total'] ?? cartData['subtotal'] ?? 0).toDouble(),
        'totalItems': cartData['totalItems'] ?? 0,
        'data': jsonEncode(cartData),
        'lastSynced': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save cart items
    if (cartData['items'] != null) {
      final items = cartData['items'] as List<dynamic>;
      final batch = db.batch();

      for (var item in items) {
        final productData = item['productId'] is Map
            ? item['productId']
            : {'_id': item['productId']};

        batch.insert(
          tableCartItems,
          {
            'id': item['_id'] ?? item['id'] ?? '',
            'cartId': cartData['_id'] ?? cartData['id'] ?? '',
            'productId': productData['_id'] ?? productData['id'] ?? '',
            'quantity': item['quantity'] ?? 1,
            'price': (item['price'] ?? 0).toDouble(),
            'total': (item['total'] ?? 0).toDouble(),
            'productData': jsonEncode(productData),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    }

    debugPrint('[DatabaseService] Saved cart to cache');
  }

  static Future<Map<String, dynamic>?> getCart() async {
    final db = await database;
    final result = await db.query(tableCart, limit: 1);

    if (result.isEmpty) return null;

    return jsonDecode(result.first['data'] as String) as Map<String, dynamic>;
  }

  static Future<void> clearCart() async {
    final db = await database;
    await db.delete(tableCart);
    await db.delete(tableCartItems);
    debugPrint('[DatabaseService] Cleared cart from cache');
  }

  // ========== Optimistic Cart Updates ==========
  static Future<Map<String, dynamic>> optimisticAddToCart(
    Map<String, dynamic> productData,
    int quantity,
  ) async {
    try {

      // Get current cart or create new
      final currentCart = await getCart();
      Map<String, dynamic> cartData;

      if (currentCart != null) {
        cartData = Map<String, dynamic>.from(currentCart);
        final items = (cartData['items'] as List<dynamic>?) ?? [];
        
        // Check if product already in cart
        final existingItemIndex = items.indexWhere(
          (item) => (item['productId'] is Map
                  ? item['productId']['_id']
                  : item['productId']) == productData['_id'],
        );

        if (existingItemIndex >= 0) {
          // Update quantity
          final existingItem = items[existingItemIndex] as Map<String, dynamic>;
          final newQuantity = (existingItem['quantity'] as int? ?? 0) + quantity;
          final price = (productData['price'] ?? productData['unitPrice'] ?? 0).toDouble();
          existingItem['quantity'] = newQuantity;
          existingItem['total'] = price * newQuantity;
        } else {
          // Add new item
          final price = (productData['price'] ?? productData['unitPrice'] ?? 0).toDouble();
          items.add({
            '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
            'productId': productData,
            'quantity': quantity,
            'price': price,
            'total': price * quantity,
          });
        }

        cartData['items'] = items;
        // Recalculate totals
        double subtotal = 0;
        int totalItems = 0;
        for (var item in items) {
          subtotal += (item['total'] ?? 0).toDouble();
          totalItems += (item['quantity'] ?? 0) as int;
        }
        cartData['subtotal'] = subtotal;
        cartData['total'] = subtotal;
        cartData['totalItems'] = totalItems;
      } else {
        // Create new cart
        final price = (productData['price'] ?? productData['unitPrice'] ?? 0).toDouble();
        cartData = {
          '_id': 'temp_cart_${DateTime.now().millisecondsSinceEpoch}',
          'userId': null,
          'items': [
            {
              '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
              'productId': productData,
              'quantity': quantity,
              'price': price,
              'total': price * quantity,
            }
          ],
          'subtotal': price * quantity,
          'total': price * quantity,
          'totalItems': quantity,
        };
      }

      // Save to database
      await saveCart(cartData);
      debugPrint('[DatabaseService] Optimistically added product to cart');
      return cartData;
    } catch (e) {
      debugPrint('[DatabaseService] Error in optimisticAddToCart: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> optimisticRemoveFromCart(String productId) async {
    try {
      final currentCart = await getCart();

      if (currentCart == null) return null;

      final cartData = Map<String, dynamic>.from(currentCart);
      final items = (cartData['items'] as List<dynamic>?) ?? [];

      // Remove item
      items.removeWhere((item) {
        final itemProductId = item['productId'] is Map
            ? item['productId']['_id']
            : item['productId'];
        return itemProductId == productId;
      });

      cartData['items'] = items;

      // Recalculate totals
      double subtotal = 0;
      int totalItems = 0;
      for (var item in items) {
        subtotal += (item['total'] ?? 0).toDouble();
        totalItems += (item['quantity'] ?? 0) as int;
      }
      cartData['subtotal'] = subtotal;
      cartData['total'] = subtotal;
      cartData['totalItems'] = totalItems;

      // Save to database
      if (items.isEmpty) {
        await clearCart();
        return null;
      } else {
        await saveCart(cartData);
      }

      debugPrint('[DatabaseService] Optimistically removed product from cart');
      return cartData;
    } catch (e) {
      debugPrint('[DatabaseService] Error in optimisticRemoveFromCart: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> optimisticUpdateCartQuantity(
    String productId,
    int quantity,
  ) async {
    try {
      final currentCart = await getCart();
      if (currentCart == null) {
        throw Exception('Cart not found');
      }

      final cartData = Map<String, dynamic>.from(currentCart);
      final items = (cartData['items'] as List<dynamic>?) ?? [];

      final itemIndex = items.indexWhere((item) {
        final itemProductId = item['productId'] is Map
            ? item['productId']['_id']
            : item['productId'];
        return itemProductId == productId;
      });

      if (itemIndex >= 0) {
        final item = items[itemIndex] as Map<String, dynamic>;
        final price = (item['price'] ?? 0).toDouble();
        item['quantity'] = quantity;
        item['total'] = price * quantity;

        // Recalculate totals
        double subtotal = 0;
        int totalItems = 0;
        for (var cartItem in items) {
          subtotal += (cartItem['total'] ?? 0).toDouble();
          totalItems += (cartItem['quantity'] ?? 0) as int;
        }
        cartData['subtotal'] = subtotal;
        cartData['total'] = subtotal;
        cartData['totalItems'] = totalItems;

        await saveCart(cartData);
        debugPrint('[DatabaseService] Optimistically updated cart quantity');
      }

      return cartData;
    } catch (e) {
      debugPrint('[DatabaseService] Error in optimisticUpdateCartQuantity: $e');
      rethrow;
    }
  }

  // ========== Orders ==========
  static Future<void> saveOrders(List<Map<String, dynamic>> orders) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var order in orders) {
      // Save order
      batch.insert(
        tableOrders,
        {
          'id': order['_id'] ?? order['id'] ?? '',
          'orderId': order['orderId'] ?? '',
          'userId': order['userId'],
          'orderStatus': order['orderStatus'] ?? 'pending',
          'paymentStatus': order['paymentStatus'] ?? 'pending',
          'paymentMethod': order['paymentMethod'],
          'subtotal': (order['subtotal'] ?? 0).toDouble(),
          'tax': (order['tax'] ?? 0).toDouble(),
          'shippingCost': (order['shippingCost'] ?? 0).toDouble(),
          'total': (order['total'] ?? 0).toDouble(),
          'discountAmount': (order['discountAmount'] ?? 0).toDouble(),
          'shippingAddress': order['shippingAddress'] != null
              ? jsonEncode(order['shippingAddress'])
              : null,
          'billingAddress': order['billingAddress'] != null
              ? jsonEncode(order['billingAddress'])
              : null,
          'createdAt': order['createdAt'],
          'updatedAt': order['updatedAt'],
          'data': jsonEncode(order),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save order items
      if (order['items'] != null) {
        final items = order['items'] as List<dynamic>;
        for (var item in items) {
          batch.insert(
            tableOrderItems,
            {
              'id': item['_id'] ?? item['id'] ?? '',
              'orderId': order['_id'] ?? order['id'] ?? '',
              'productId': item['productId'] ?? '',
              'name': item['name'] ?? '',
              'price': (item['price'] ?? 0).toDouble(),
              'quantity': item['quantity'] ?? 1,
              'total': (item['total'] ?? 0).toDouble(),
              'productData': jsonEncode(item),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${orders.length} orders to cache');
  }

  static Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    final db = await database;
    String query = 'SELECT * FROM $tableOrders WHERE 1=1';
    List<dynamic> args = [];

    if (status != null && status != 'all') {
      query += ' AND orderStatus = ?';
      args.add(status);
    }

    query += ' ORDER BY createdAt DESC';

    final results = await db.rawQuery(query, args);
    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  /// Update order status in SQLite (e.g. cancelled). Keeps cache in sync so Cancelled tab shows correct list.
  static Future<void> updateOrderStatus(
    String orderId,
    String orderStatus, {
    DateTime? updatedAt,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        tableOrders,
        where: 'orderId = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final dataStr = rows.first['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) return;
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      final now = updatedAt ?? DateTime.now();
      data['orderStatus'] = orderStatus;
      data['updatedAt'] = now.toIso8601String();
      await db.update(
        tableOrders,
        {
          'orderStatus': orderStatus,
          'updatedAt': now.toIso8601String(),
          'data': jsonEncode(data),
          'lastSynced': _getCurrentTimestamp(),
        },
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      debugPrint('[DatabaseService] Updated order $orderId status to $orderStatus in cache');
    } catch (e) {
      debugPrint('[DatabaseService] Error updating order status: $e');
    }
  }

  // ========== Addresses ==========
  static Future<void> saveAddresses(List<Map<String, dynamic>> addresses) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var address in addresses) {
      batch.insert(
        tableAddresses,
        {
          'id': address['_id'] ?? address['id'] ?? '',
          'userId': address['userId'],
          'fullName': address['fullName'] ?? '',
          'phone': address['phone'],
          'street': address['street'],
          'city': address['city'],
          'postalCode': address['postalCode'],
          'country': address['country'],
          'isDefault': (address['isDefault'] ?? false) ? 1 : 0,
          'data': jsonEncode(address),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${addresses.length} addresses to cache');
  }

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final db = await database;
    final results = await db.query(
      tableAddresses,
      orderBy: 'isDefault DESC',
    );

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ========== Coupons ==========
  static Future<void> saveCoupons(List<Map<String, dynamic>> coupons) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    for (var coupon in coupons) {
      batch.insert(
        tableCoupons,
        {
          'id': coupon['_id'] ?? coupon['id'] ?? '',
          'code': coupon['code'] ?? '',
          'description': coupon['description'],
          'discountType': coupon['discountType'],
          'discountValue': (coupon['discountValue'] ?? 0).toDouble(),
          'minPurchase': (coupon['minPurchase'] ?? 0).toDouble(),
          'maxDiscount': coupon['maxDiscount'] != null
              ? (coupon['maxDiscount'] as num).toDouble()
              : null,
          'validFrom': coupon['validFrom'],
          'validUntil': coupon['validUntil'],
          'isActive': (coupon['isActive'] ?? true) ? 1 : 0,
          'usageLimit': coupon['usageLimit'],
          'usedCount': coupon['usedCount'] ?? 0,
          'data': jsonEncode(coupon),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved ${coupons.length} coupons to cache');
  }

  static Future<List<Map<String, dynamic>>> getCoupons() async {
    final db = await database;
    final results = await db.query(
      tableCoupons,
      where: 'isActive = ?',
      whereArgs: [1],
    );

    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ========== Wishlist ==========
  static Future<void> saveWishlist(List<Map<String, dynamic>> wishlistItems) async {
    final db = await database;
    final batch = db.batch();
    final timestamp = _getCurrentTimestamp();

    // Clear existing wishlist
    await db.delete(tableWishlist);

    for (var item in wishlistItems) {
      if (item['productIds'] != null) {
        final products = item['productIds'] as List<dynamic>;
        for (var product in products) {
          final productData = product is Map ? product : {'_id': product};
          batch.insert(
            tableWishlist,
            {
              'id': '${item['_id']}_${productData['_id']}',
              'userId': item['userId'],
              'productId': productData['_id'] ?? productData['id'] ?? '',
              'productData': jsonEncode(productData),
              'createdAt': item['createdAt'],
              'lastSynced': timestamp,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Saved wishlist to cache');
  }

  static Future<List<Map<String, dynamic>>> getWishlist() async {
    final db = await database;
    final results = await db.query(tableWishlist, orderBy: 'createdAt DESC');

    return results.map((row) {
      return jsonDecode(row['productData'] as String) as Map<String, dynamic>;
    }).toList();
  }

  // ========== Optimistic Wishlist Updates ==========
  static Future<void> optimisticAddToWishlist(Map<String, dynamic> productData) async {
    try {
      final db = await database;
      final timestamp = _getCurrentTimestamp();
      final productId = productData['_id'] ?? productData['id'] ?? '';

      // Check if already in wishlist
      final existing = await db.query(
        tableWishlist,
        where: 'productId = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (existing.isEmpty) {
        // Get userId from storage or use placeholder
        final userId = 'current_user'; // Will be updated when API syncs

        await db.insert(
          tableWishlist,
          {
            'id': 'temp_${productId}_$timestamp',
            'userId': userId,
            'productId': productId,
            'productData': jsonEncode(productData),
            'createdAt': DateTime.now().toIso8601String(),
            'lastSynced': timestamp,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('[DatabaseService] Optimistically added product to wishlist');
      }
    } catch (e) {
      debugPrint('[DatabaseService] Error in optimisticAddToWishlist: $e');
      rethrow;
    }
  }

  static Future<void> optimisticRemoveFromWishlist(String productId) async {
    try {
      final db = await database;
      await db.delete(
        tableWishlist,
        where: 'productId = ?',
        whereArgs: [productId],
      );
      debugPrint('[DatabaseService] Optimistically removed product from wishlist');
    } catch (e) {
      debugPrint('[DatabaseService] Error in optimisticRemoveFromWishlist: $e');
      rethrow;
    }
  }

  // ========== User Profile ==========
  static Future<void> saveUserProfile(Map<String, dynamic> userData) async {
    try {
      final db = await database;
      final timestamp = _getCurrentTimestamp();
      final userId = userData['_id'] ?? userData['id'] ?? '';

      await db.insert(
        tableUser,
        {
          'id': userId,
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'role': userData['role'] ?? 'user',
          'isEmailVerified': (userData['isEmailVerified'] ?? false) ? 1 : 0,
          'status': userData['status'] ?? 'active',
          'isDeleted': (userData['isDeleted'] ?? false) ? 1 : 0,
          'mobile': userData['mobile'],
          'profileImage': userData['profilePicture'] ?? userData['profileImage'],
          'createdAt': userData['createdAt'],
          'updatedAt': userData['updatedAt'],
          'data': jsonEncode(userData),
          'lastSynced': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('[DatabaseService] Saved user profile to cache');
    } catch (e) {
      debugPrint('[DatabaseService] Error saving user profile: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final db = await database;
      final result = await db.query(tableUser, limit: 1);

      if (result.isEmpty) return null;

      try {
        final dataString = result.first['data'] as String?;
        if (dataString != null && dataString.isNotEmpty) {
          final decoded = jsonDecode(dataString);
          return decoded as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[DatabaseService] Error decoding user profile: $e');
      }

      // Fallback: reconstruct from row data
      final row = result.first;
      return {
        '_id': row['id'] as String? ?? '',
        'id': row['id'] as String? ?? '',
        'name': row['name'] as String? ?? '',
        'email': row['email'] as String? ?? '',
        'role': row['role'] as String? ?? 'user',
        'isEmailVerified': (row['isEmailVerified'] as int? ?? 0) == 1,
        'status': row['status'] as String? ?? 'active',
        'isDeleted': (row['isDeleted'] as int? ?? 0) == 1,
        'mobile': row['mobile'] as String?,
        'profilePicture': row['profileImage'] as String?,
        'profileImage': row['profileImage'] as String?,
        'createdAt': row['createdAt'] as String?,
        'updatedAt': row['updatedAt'] as String?,
      };
    } catch (e) {
      debugPrint('[DatabaseService] Error getting user profile: $e');
      return null;
    }
  }

  static Future<void> clearUserProfile() async {
    try {
      final db = await database;
      await db.delete(tableUser);
      debugPrint('[DatabaseService] Cleared user profile from cache');
    } catch (e) {
      debugPrint('[DatabaseService] Error clearing user profile: $e');
    }
  }

  // ========== Cache Metadata ==========
  static Future<void> setCacheMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      tableCacheMeta,
      {
        'key': key,
        'value': value,
        'lastUpdated': _getCurrentTimestamp(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getCacheMeta(String key) async {
    final db = await database;
    final result = await db.query(
      tableCacheMeta,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // ========== Clear All Data ==========
  static Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();

    batch.delete(tableProducts);
    batch.delete(tableCategories);
    batch.delete(tableCarousels);
    batch.delete(tableFlashSales);
    batch.delete(tableCart);
    batch.delete(tableCartItems);
    batch.delete(tableOrders);
    batch.delete(tableOrderItems);
    batch.delete(tableAddresses);
    batch.delete(tableCoupons);
    batch.delete(tableWishlist);
    batch.delete(tableCacheMeta);

    await batch.commit(noResult: true);
    debugPrint('[DatabaseService] Cleared all cached data');
  }

  // ========== Check if data is stale ==========
  static Future<bool> isDataStale(String tableName, {int maxAgeMinutes = 30}) async {
    try {
      final db = await database;
      final result = await db.query(
        tableName,
        columns: ['lastSynced'],
        limit: 1,
        orderBy: 'lastSynced DESC',
      );

      if (result.isEmpty) return true;

      final lastSynced = result.first['lastSynced'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - lastSynced;
      final maxAge = maxAgeMinutes * 60 * 1000;

      return age > maxAge;
    } catch (e) {
      debugPrint('[DatabaseService] Error checking data staleness: $e');
      return true; // Assume stale if error
    }
  }
}
