class AppConstants {
  // Input Field Limits
  static const int mobileMaxLength = 11;
  static const int passwordMaxLength = 20;
  static const int nameMaxLength = 50;
  static const int emailMaxLength = 100;
  
  // Validation
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String mobilePattern = r'^[0-9]{11}$';
  
  // Currency
  static const String currencySymbol = '৳';
  
  // API Timeouts
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
