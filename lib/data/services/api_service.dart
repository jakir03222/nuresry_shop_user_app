import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/storage_service.dart';

class ApiService {
  // Base API call method
  static Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    String? token,
    bool requireAuth = false,
  }) async {
    // If auth is required, get token from storage if not provided
    String? authToken = token;
    if (requireAuth && authToken == null) {
      authToken = await StorageService.getAccessToken();
    }
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final headers = {'Content-Type': ApiConstants.contentType};

      if (authToken != null) {
        headers[ApiConstants.authorization] =
            '${ApiConstants.bearer} $authToken';
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Request failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  static const List<String> _allowedImageMimes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static Future<http.MultipartFile> _profilePicturePart(File file) async {
    final path = file.path;
    final mimeType = lookupMimeType(path);
    final contentType =
        (mimeType != null && _allowedImageMimes.contains(mimeType))
        ? MediaType.parse(mimeType)
        : MediaType('image', 'jpeg');
    var filename = path.split(Platform.pathSeparator).last;
    if (!filename.contains('.')) {
      filename = 'profilePicture.${contentType.subtype}';
    }
    return http.MultipartFile.fromPath(
      'profilePicture',
      path,
      filename: filename,
      contentType: contentType,
    );
  }

  // Sign Up - supports either email or phone
  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String emailOrPhone,
    required String password,
    File? profileImage,
  }) async {
    if (emailOrPhone.trim().isEmpty) {
      throw Exception('Email or phone is required');
    }
    
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signUp}');
      debugPrint('[signUp] API URL: $url');
      debugPrint('[signUp] Request Data:');
      debugPrint('  - name: $name');
      debugPrint('  - emailOrPhone: $emailOrPhone');
      debugPrint('  - password: ${'*' * password.length}');
      debugPrint('  - role: user');
      debugPrint(
        '  - profileImage: ${profileImage != null ? profileImage.path : 'null'}',
      );

      var request = http.MultipartRequest('POST', url);

      final headers = {
        'Accept': 'application/json',
      };
      request.headers.addAll(headers);

      // Add required fields: name, emailOrPhone, password, role
      request.fields.addAll({
        'name': name,
        'emailOrPhone': emailOrPhone.trim(),
        'password': password,
        'role': 'user', // use 'user' for app; server may accept 'admin'
      });

      debugPrint('[signUp] Request fields: ${request.fields}');

      if (profileImage != null) {
        final filePart = await _profilePicturePart(profileImage);
        request.files.add(filePart);
        debugPrint('[signUp] Profile image added: ${filePart.filename}');
      }

      debugPrint('[signUp] Sending request...');
      http.StreamedResponse streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[signUp] Response Status Code: ${response.statusCode}');
      debugPrint('[signUp] Response Headers: ${response.headers}');
      debugPrint('[signUp] Response Body: ${response.body}');

      // Parse response body
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[signUp] Parsed Response Data: $responseData');
      } catch (e) {
        debugPrint('[signUp] Failed to parse response body: $e');
        throw Exception('Invalid response from server');
      }

      // Check for success status codes (200, 201, etc.)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check if success is true in the response
        if (responseData['success'] == true) {
          debugPrint('[signUp] Signup successful!');
          debugPrint('[signUp] Message: ${responseData['message']}');
          if (responseData['data'] != null) {
            debugPrint('[signUp] User Data: ${responseData['data']}');
          }
          return responseData;
        } else {
          final errorMessage = responseData['message'] ?? 'Sign up failed';
          debugPrint('[signUp] Signup failed: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        // Handle error status codes
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Sign up failed with status ${response.statusCode}';
        debugPrint('[signUp] HTTP Error ${response.statusCode}: $errorMessage');
        debugPrint('[signUp] Error Response: $responseData');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('[signUp] Exception occurred: $e');
      debugPrint('[signUp] Stack Trace: $stackTrace');
      rethrow;
    }
  }

  // Verify Email
  static Future<Map<String, dynamic>> verifyEmail({
    required String otp,
    required String email,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.verifyEmail,
      method: 'POST',
      body: {'email': email, 'otp': otp},
    );
  }

  // Login - supports both email and phone
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    if (emailOrPhone.trim().isEmpty) {
      throw Exception('Email or phone is required');
    }
    
    final body = <String, dynamic>{
      'emailOrPhone': emailOrPhone.trim(),
      'password': password,
    };
    
    return await _makeRequest(
      endpoint: ApiConstants.login,
      method: 'POST',
      body: body,
    );
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.forgotPassword,
      method: 'POST',
      body: {'email': email},
    );
  }

  // Change Password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.changePassword,
      method: 'POST',
      body: {'oldPassword': currentPassword, 'newPassword': newPassword},
      requireAuth: true, // Require authentication token
    );
  }

  // Get Carousels
  static Future<Map<String, dynamic>> getCarousels() async {
    return await _makeRequest(
      endpoint: ApiConstants.carousels,
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Get Categories
  static Future<Map<String, dynamic>> getCategories() async {
    return await _makeRequest(endpoint: ApiConstants.categories, method: 'GET');
  }

  // Get Category by ID
  static Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    return await _makeRequest(
      endpoint: ApiConstants.categoryById(categoryId),
      method: 'GET',
    );
  }

  // Get Active Flash Sales
  static Future<Map<String, dynamic>> getActiveFlashSales({
    int page = 1,
    int limit = 100,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.flashSalesActive(page: page, limit: limit),
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Get Flash Sale by ID
  static Future<Map<String, dynamic>> getFlashSaleById(String saleId) async {
    return await _makeRequest(
      endpoint: ApiConstants.flashSaleById(saleId),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Get Products by Flash Sale
  static Future<Map<String, dynamic>> getProductsByFlashSale(
    String saleId,
  ) async {
    return await _makeRequest(
      endpoint: ApiConstants.productsByFlashSale(saleId),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Get Products by Category
  static Future<Map<String, dynamic>> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    final endpoint = ApiConstants.productsByCategory(
      categoryId,
      page: page,
      limit: limit,
    );
    final url = '${ApiConstants.baseUrl}$endpoint';
    
    debugPrint('[ApiService.getProductsByCategory] ========== API CALL START ==========');
    debugPrint('[ApiService.getProductsByCategory] URL: $url');
    debugPrint('[ApiService.getProductsByCategory] Method: GET');
    debugPrint('[ApiService.getProductsByCategory] Parameters:');
    debugPrint('  - categoryId: $categoryId');
    debugPrint('  - page: $page');
    debugPrint('  - limit: $limit');
    debugPrint('[ApiService.getProductsByCategory] Require Auth: true');
    
    try {
      final response = await _makeRequest(
        endpoint: endpoint,
        method: 'GET',
        requireAuth: true, // Require authentication token
      );
      
      debugPrint('[ApiService.getProductsByCategory] ========== API CALL SUCCESS ==========');
      debugPrint('[ApiService.getProductsByCategory] Response success: ${response['success']}');
      debugPrint('[ApiService.getProductsByCategory] Response message: ${response['message']}');
      
      if (response['data'] != null) {
        if (response['data'] is List) {
          debugPrint('[ApiService.getProductsByCategory] Response data type: List');
          debugPrint('[ApiService.getProductsByCategory] Response data length: ${(response['data'] as List).length}');
        } else {
          debugPrint('[ApiService.getProductsByCategory] Response data type: ${response['data'].runtimeType}');
        }
      } else {
        debugPrint('[ApiService.getProductsByCategory] Response data: null');
      }
      
      if (response['meta'] != null) {
        debugPrint('[ApiService.getProductsByCategory] Response meta: ${response['meta']}');
      }
      
      return response;
    } catch (e, stackTrace) {
      debugPrint('[ApiService.getProductsByCategory] ========== API CALL ERROR ==========');
      debugPrint('[ApiService.getProductsByCategory] Error: $e');
      debugPrint('[ApiService.getProductsByCategory] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get All Products
  static Future<Map<String, dynamic>> getAllProducts({
    int page = 1,
    int limit = 1000,
  }) async {
    final endpoint = ApiConstants.allProducts(page: page, limit: limit);
    return await _makeRequest(
      endpoint: endpoint,
      method: 'GET',
      requireAuth: true,
    );
  }

  /// GET {{baseUrl}}/products/:id – product detail (name, sku, description, image, images, price, discount, quantity, isAvailable, isFeatured, brand, categoryId, tags, deliveryTime, courierCharge, ratingAverage, ratingCount, createdAt, updatedAt)
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    return await _makeRequest(
      endpoint: ApiConstants.productById(productId),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Search Products by Tags and/or Name
  static Future<Map<String, dynamic>> searchProductsByTags({
    String? tags,
    String? searchTerm,
    int page = 1,
    int limit = 10,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.productsByTags(
        tags: tags,
        searchTerm: searchTerm,
        page: page,
        limit: limit,
      ),
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Get Cart
  static Future<Map<String, dynamic>> getCart() async {
    return await _makeRequest(
      endpoint: ApiConstants.carts,
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Add to Cart
  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.addToCart,
      method: 'POST',
      body: {'productId': productId, 'quantity': quantity},
      requireAuth: true, // Require authentication token
    );
  }

  // Update Cart Item Quantity
  static Future<Map<String, dynamic>> updateCartItemQuantity({
    required String productId,
    required int quantity,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.updateCartItem(productId),
      method: 'PATCH',
      body: {'quantity': quantity},
      requireAuth: true, // Require authentication token
    );
  }

  // Remove Cart Item
  static Future<Map<String, dynamic>> removeCartItem(String productId) async {
    return await _makeRequest(
      endpoint: ApiConstants.removeCartItem(productId),
      method: 'DELETE',
      requireAuth: true, // Require authentication token
    );
  }

  // Clear Cart
  static Future<Map<String, dynamic>> clearCart() async {
    return await _makeRequest(
      endpoint: ApiConstants.carts,
      method: 'DELETE',
      requireAuth: true, // Require authentication token
    );
  }

  // Address Endpoints
  // Get All Addresses
  static Future<Map<String, dynamic>> getAddresses() async {
    return await _makeRequest(
      endpoint: ApiConstants.addresses,
      method: 'GET',
      requireAuth: true,
    );
  }

  // Create Address
  static Future<Map<String, dynamic>> createAddress({
    required String street,
    required String city,
    required String postalCode,
    required String country,
    required String phoneNumber,
    bool isDefault = false,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.addresses,
      method: 'POST',
      body: {
        'street': street,
        'city': city,
        'postalCode': postalCode,
        'country': country,
        'phoneNumber': phoneNumber,
        'isDefault': isDefault,
      },
      requireAuth: true,
    );
  }

  // Update Address
  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (street != null) body['street'] = street;
    if (city != null) body['city'] = city;
    if (postalCode != null) body['postalCode'] = postalCode;
    if (country != null) body['country'] = country;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (isDefault != null) body['isDefault'] = isDefault;

    return await _makeRequest(
      endpoint: ApiConstants.addressById(addressId),
      method: 'PATCH',
      body: body,
      requireAuth: true,
    );
  }

  // Delete Address
  static Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    return await _makeRequest(
      endpoint: ApiConstants.addressById(addressId),
      method: 'DELETE',
      requireAuth: true,
    );
  }

  // Order Endpoints
  // Get My Orders
  static Future<Map<String, dynamic>> getMyOrders({
    int page = 1,
    int limit = 10,
    String? orderStatus,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.ordersMy(
        page: page,
        limit: limit,
        orderStatus: orderStatus,
      ),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Create Order
  // For COD: do not pass transactionId. For online (bkash, nagad, rocket): pass transactionId.
  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddressId,
    required List<String> selectedProductIds,
    required String paymentMethod,
    String? notes,
    String? transactionId,
    String? discountCode,
  }) async {
    final body = <String, dynamic>{
      'shippingAddressId': shippingAddressId,
      'selectedProductIds': selectedProductIds,
      'paymentMethod': paymentMethod.toLowerCase(),
    };

    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    if (transactionId != null && transactionId.trim().isNotEmpty) {
      body['transactionId'] = transactionId.trim();
    }
    if (discountCode != null && discountCode.trim().isNotEmpty) {
      body['discountCode'] = discountCode.trim();
    }

    return await _makeRequest(
      endpoint: ApiConstants.orders,
      method: 'POST',
      body: body,
      requireAuth: true,
    );
  }

  // Cancel Order: PATCH {{baseUrl}}/orders/:orderId/cancel with Bearer token; body sets status to cancelled
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final endpoint = ApiConstants.orderCancel(orderId);
    final url = '${ApiConstants.baseUrl}$endpoint';
    final body = {'orderStatus': 'cancelled'};
    debugPrint('[Cancel Order API] PATCH $url');
    debugPrint('[Cancel Order API] orderId: $orderId');
    debugPrint('[Cancel Order API] body: $body');
    debugPrint('[Cancel Order API] auth: Bearer token applied');
    final response = await _makeRequest(
      endpoint: endpoint,
      method: 'PATCH',
      body: body,
      requireAuth: true,
    );
    debugPrint('[Cancel Order API] response: $response');
    return response;
  }

  // Create Transaction
  static Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required String paymentMethodId,
    required String userProvidedTransactionId,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.transactions,
      method: 'POST',
      body: {
        'orderId': orderId,
        'paymentMethodId': paymentMethodId,
        'userProvidedTransactionId': userProvidedTransactionId,
      },
      requireAuth: true,
    );
  }

  // Wishlist Endpoints
  // Get My Wishlist
  static Future<Map<String, dynamic>> getMyWishlist() async {
    return await _makeRequest(
      endpoint: ApiConstants.wishlistsMy,
      method: 'GET',
      requireAuth: true,
    );
  }

  // Add to Wishlist
  static Future<Map<String, dynamic>> addToWishlist(String productId) async {
    return await _makeRequest(
      endpoint: ApiConstants.wishlistsAdd,
      method: 'POST',
      body: {'productId': productId},
      requireAuth: true,
    );
  }

  // Remove from Wishlist
  static Future<Map<String, dynamic>> removeFromWishlist(
    String productId,
  ) async {
    return await _makeRequest(
      endpoint: ApiConstants.wishlistRemove(productId),
      method: 'DELETE',
      requireAuth: true,
    );
  }

  // Clear Wishlist
  static Future<Map<String, dynamic>> clearWishlist() async {
    return await _makeRequest(
      endpoint: ApiConstants.wishlists,
      method: 'DELETE',
      requireAuth: true,
    );
  }

  // Contact Endpoints
  // GET {{baseUrl}}/contacts — sends Authorization: Bearer <token>; response body (success, message, data) is returned.
  static Future<Map<String, dynamic>> getContacts() async {
    debugPrint(
      '[ApiService.getContacts] GET ${ApiConstants.baseUrl}${ApiConstants.contacts} (with auth token)',
    );
    return await _makeRequest(
      endpoint: ApiConstants.contacts,
      method: 'GET',
      requireAuth: true, // applies Bearer token from storage
    );
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getProfile() async {
    debugPrint(
      '[getProfile] Calling API: ${ApiConstants.baseUrl}${ApiConstants.usersProfile}',
    );
    try {
      final response = await _makeRequest(
        endpoint: ApiConstants.usersProfile,
        method: 'GET',
        requireAuth: true, // Require authentication token
      );
      debugPrint('[getProfile] API success: ${response['success']}');
      if (response['data'] != null) {
        final d = response['data'] as Map<String, dynamic>;
        debugPrint(
          '[getProfile] User data: name=${d['name']}, emailOrPhone=${d['emailOrPhone']}, profilePicture=${d['profilePicture']}, role=${d['role']}, status=${d['status']}',
        );
      }
      return response;
    } catch (e, stackTrace) {
      debugPrint('[getProfile] API error: $e');
      debugPrint('[getProfile] stackTrace: $stackTrace');
      rethrow;
    }
  }

  // Get Avatars: GET {{baseUrl}}/avatars?page=1&limit=10
  static Future<Map<String, dynamic>> getAvatars({
    int page = 1,
    int limit = 10,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.avatars(page: page, limit: limit),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Get Coupons
  static Future<Map<String, dynamic>> getCoupons({
    int page = 1,
    int limit = 10,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.coupons(page: page, limit: limit),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Review Endpoints: POST {{baseUrl}}/reviews body: { productId, rating, reviewText }; GET {{baseUrl}}/reviews/my?page=1&limit=10
  static Future<Map<String, dynamic>> createReview({
    required String productId,
    required int rating,
    required String reviewText,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.reviews,
      method: 'POST',
      body: {
        'productId': productId,
        'rating': rating,
        'reviewText': reviewText,
      },
      requireAuth: true,
    );
  }

  static Future<Map<String, dynamic>> getMyReviews({
    int page = 1,
    int limit = 10,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.reviewsMy(page: page, limit: limit),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Payment Method Endpoints
  // Get Payment Methods
  static Future<Map<String, dynamic>> getPaymentMethods() async {
    return await _makeRequest(
      endpoint: ApiConstants.paymentMethods,
      method: 'GET',
      requireAuth: true,
    );
  }

  // Update User Profile (avatarId = selected avatar from GET /avatars; profilePicture = gallery image)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? mobile,
    String? avatarId,
    File? profilePicture,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.usersUpdate}',
      );

      // Get auth token
      final authToken = await StorageService.getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      var request = http.MultipartRequest('PATCH', url);

      // Add headers
      request.headers.addAll({
        'Authorization': '${ApiConstants.bearer} $authToken',
      });

      // Add text fields if provided
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }
      if (mobile != null && mobile.isNotEmpty) {
        request.fields['mobile'] = mobile;
      }
      if (avatarId != null && avatarId.isNotEmpty) {
        request.fields['avatarId'] = avatarId;
      }

      if (profilePicture != null) {
        request.files.add(await _profilePicturePart(profilePicture));
      }

      http.StreamedResponse streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      }

      debugPrint(
        '[updateProfile] API error: statusCode=${response.statusCode}',
      );
      debugPrint('[updateProfile] response.body: ${response.body}');

      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      throw Exception(responseData?['message'] ?? 'Update profile failed');
    } catch (e, stackTrace) {
      debugPrint('[updateProfile] Exception: $e');
      debugPrint('[updateProfile] stackTrace: $stackTrace');
      rethrow;
    }
  }

  // Helper method for authenticated requests
  // Use this for API calls that require authentication
  static Future<Map<String, dynamic>> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    return await _makeRequest(
      endpoint: endpoint,
      method: method,
      body: body,
      requireAuth: true,
    );
  }
}
