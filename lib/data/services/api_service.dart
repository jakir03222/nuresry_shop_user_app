import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Sign Up
  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.signUp,
      method: 'POST',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  // Verify Email
  static Future<Map<String, dynamic>> verifyEmail({
    required String token,
    required String email,
  }) async {
    return await _makeRequest(
      endpoint: ApiConstants.verifyEmail,
      method: 'POST',
      body: {
        'token': token,
        'email': email,
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

  // Get Carousels
  static Future<Map<String, dynamic>> getCarousels() async {
    return await _makeRequest(
      endpoint: ApiConstants.carousels,
      method: 'GET',
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
