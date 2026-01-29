class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://nursery-server-phi.vercel.app/api/v1';

  // Auth Endpoints
  static const String signUp = '/auth/sign-up';
  static const String verifyEmail = '/auth/verify-email';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/request-password-reset';
  static const String changePassword = '/auth/change-password';

  // Carousel Endpoints
  static const String carousels = '/carousels';

  // Category Endpoints
  static const String categories = '/categories';
  static String categoryById(String categoryId) => '/categories/$categoryId';

  // Flash Sale Endpoints
  static String flashSalesActive({int page = 1, int limit = 100}) {
    return '/flash-sales/active?page=$page&limit=$limit';
  }

  static String flashSaleById(String saleId) => '/flash-sales/$saleId';

  // Product Endpoints
  static const String products = '/products';
  static String allProducts({int page = 1, int limit = 1000}) =>
      '/products?page=$page&limit=$limit';
  static String productById(String productId) => '/products/$productId';
  static String productsByFlashSale(String saleId) =>
      '/products?flashSale=$saleId';
  static String productsByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
  }) {
    return '/products/category/$categoryId?page=$page&limit=$limit';
  }
  static String productsByTags({
    String? tags,
    String? searchTerm,
    int page = 1,
    int limit = 10,
  }) {
    var queryParams = <String>[];
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams.add('searchTerm=${Uri.encodeComponent(searchTerm)}');
    }
    if (tags != null && tags.isNotEmpty) {
      queryParams.add('tags=${Uri.encodeComponent(tags)}');
    }
    queryParams.add('page=$page');
    queryParams.add('limit=$limit');
    return '/products?${queryParams.join('&')}';
  }

  // Cart Endpoints
  static const String carts = '/carts';
  static const String addToCart = '/carts/add';
  static String updateCartItem(String productId) => '/carts/$productId';
  static String removeCartItem(String productId) => '/carts/$productId';

  // Address Endpoints
  static const String addresses = '/addresses';
  static String addressById(String addressId) => '/addresses/$addressId';

  // Order Endpoints
  static const String orders = '/orders';
  /// Cancel order (User): PATCH {{baseUrl}}/orders/:orderId/cancel
  static String orderCancel(String orderId) => '/orders/$orderId/cancel';
  static String ordersMy({int page = 1, int limit = 10, String? orderStatus}) {
    var path = '/orders/my?page=$page&limit=$limit';
    if (orderStatus != null && orderStatus.isNotEmpty && orderStatus != 'all') {
      path += '&orderStatus=$orderStatus';
    }
    return path;
  }

  // Transaction Endpoints
  static const String transactions = '/transactions';

  // Wishlist Endpoints
  static const String wishlists = '/wishlists';
  static const String wishlistsMy = '/wishlists/my';
  static const String wishlistsAdd = '/wishlists/add';
  static String wishlistRemove(String productId) => '/wishlists/$productId';

  // Contact Endpoints
  static const String contacts = '/contacts';

  // User Endpoints
  static const String usersUpdate = '/users/update';
  static const String usersProfile = '/users/profile';

  // Avatars: GET {{baseUrl}}/avatars?page=1&limit=10
  static String avatars({int page = 1, int limit = 10}) =>
      '/avatars?page=$page&limit=$limit';

  // Coupon Endpoints
  static String coupons({int page = 1, int limit = 10}) =>
      '/coupons?page=$page&limit=$limit';

  // Review Endpoints: POST {{baseUrl}}/reviews (body: productId, rating, reviewText); GET {{baseUrl}}/reviews/my?page=1&limit=10
  static const String reviews = '/reviews';
  static String reviewsMy({int page = 1, int limit = 10}) =>
      '/reviews/my?page=$page&limit=$limit';

  // Payment Method Endpoints
  static const String paymentMethods = '/payment-methods';

  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
