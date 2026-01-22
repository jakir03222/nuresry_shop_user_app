class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://nursery-server-phi.vercel.app/api/v1';
  
  // Auth Endpoints
  static const String signUp = '/auth/sign-up';
  static const String verifyEmail = '/auth/verify-email';
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  
  // Carousel Endpoints
  static const String carousels = '/carousels';
  
  // Category Endpoints
  static const String categories = '/categories';
  
  // Flash Sale Endpoints
  static const String flashSalesActive = '/flash-sales/active';
  static String flashSaleById(String saleId) => '/flash-sales/$saleId';
  
  // Product Endpoints
  static const String products = '/products';
  static String productsByFlashSale(String saleId) => '/products?flashSale=$saleId';
  
  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
