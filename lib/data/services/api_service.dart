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
      
      final headers = {
        'Content-Type': ApiConstants.contentType,
      };

      if (authToken != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $authToken';
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
          response = await http.delete(url, headers: headers);
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

  static const List<String> _allowedImageMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

  static Future<http.MultipartFile> _profilePicturePart(File file) async {
    final path = file.path;
    final mimeType = lookupMimeType(path);
    final contentType = (mimeType != null && _allowedImageMimes.contains(mimeType))
        ? MediaType.parse(mimeType)
        : MediaType('image', 'jpeg');
    var filename = path.split(Platform.pathSeparator).last;
    if (!filename.contains('.')) {
      filename = 'profilePicture.${contentType.subtype}';
    }
    return http.MultipartFile.fromPath('profilePicture', path, filename: filename, contentType: contentType);
  }

  // Sign Up
  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    File? profileImage,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signUp}');
      
      var request = http.MultipartRequest('POST', url);
      
      // Add text fields
      request.fields.addAll({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'user'  // Default role for user registration
      });
      
      if (profileImage != null) {
        request.files.add(await _profilePicturePart(profileImage));
      }
      
      http.StreamedResponse streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check if success is true in the response
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(responseData['message'] ?? 'Sign up failed');
        }
      } else {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(responseData['message'] ?? 'Sign up failed');
      }
    } catch (e) {
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
      body: {
        'email': email,
        'otp': otp,
      },
    );
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.login,
      method: 'POST',
      body: {
        'email': email,
        'password': password,
      },
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
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
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
    return await _makeRequest(
      endpoint: ApiConstants.categories,
      method: 'GET',
    );
  }

  // Get Active Flash Sales
  static Future<Map<String, dynamic>> getActiveFlashSales() async {
    return await _makeRequest(
      endpoint: ApiConstants.flashSalesActive,
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Get Flash Sale by ID
  static Future<Map<String, dynamic>> getFlashSaleById(String saleId) async {
    return await _makeRequest(
      endpoint: ApiConstants.flashSaleById(saleId),
      method: 'GET',
    );
  }

  // Get Products by Flash Sale
  static Future<Map<String, dynamic>> getProductsByFlashSale(String saleId) async {
    return await _makeRequest(
      endpoint: ApiConstants.productsByFlashSale(saleId),
      method: 'GET',
    );
  }

  // Get Products by Category
  static Future<Map<String, dynamic>> getProductsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.productsByCategory(categoryId, page: page, limit: limit),
      method: 'GET',
      requireAuth: true, // Require authentication token
    );
  }

  // Get Product by ID
  static Future<Map<String, dynamic>> getProductById(String productId) async {
    return await _makeRequest(
      endpoint: ApiConstants.productById(productId),
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
      body: {
        'productId': productId,
        'quantity': quantity,
      },
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
      body: {
        'quantity': quantity,
      },
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
  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddressId,
    required List<String> selectedProductIds,
    required String paymentMethod,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'shippingAddressId': shippingAddressId,
      'selectedProductIds': selectedProductIds,
      'paymentMethod': paymentMethod.toLowerCase(),
    };
    
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }

    return await _makeRequest(
      endpoint: ApiConstants.orders,
      method: 'POST',
      body: body,
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
      body: {
        'productId': productId,
      },
      requireAuth: true,
    );
  }

  // Remove from Wishlist
  static Future<Map<String, dynamic>> removeFromWishlist(String productId) async {
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
  // Get Contacts
  static Future<Map<String, dynamic>> getContacts() async {
    return await _makeRequest(
      endpoint: ApiConstants.contacts,
      method: 'GET',
      requireAuth: true,
    );
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getProfile() async {
    debugPrint('[getProfile] Calling API: ${ApiConstants.baseUrl}${ApiConstants.usersProfile}');
    try {
      final response = await _makeRequest(
        endpoint: ApiConstants.usersProfile,
        method: 'GET',
        requireAuth: true, // Require authentication token
      );
      debugPrint('[getProfile] API success: ${response['success']}');
      if (response['data'] != null) {
        debugPrint('[getProfile] User data: name=${response['data']['name']}, email=${response['data']['email']}, profilePicture=${response['data']['profilePicture']}');
      }
      return response;
    } catch (e, stackTrace) {
      debugPrint('[getProfile] API error: $e');
      debugPrint('[getProfile] stackTrace: $stackTrace');
      rethrow;
    }
  }

  // Get Coupons
  static Future<Map<String, dynamic>> getCoupons({int page = 1, int limit = 10}) async {
    return await _makeRequest(
      endpoint: ApiConstants.coupons(page: page, limit: limit),
      method: 'GET',
      requireAuth: true,
    );
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? mobile,
    File? profilePicture,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersUpdate}');
      
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

      if (profilePicture != null) {
        request.files.add(await _profilePicturePart(profilePicture));
      }
      
      http.StreamedResponse streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      }

      debugPrint('[updateProfile] API error: statusCode=${response.statusCode}');
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
