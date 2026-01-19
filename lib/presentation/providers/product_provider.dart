import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_model.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _flashSaleProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get flashSaleProducts => _flashSaleProducts;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data with more products
      _products = [
        // Category 1 - Mango
        ProductModel(
          id: '1',
          name: 'Biman Bangladesh Mango',
          description: 'Fresh and sweet mango from Bangladesh',
          imageUrl: 'https://images.unsplash.com/photo-1605027990121-cbae0f43b5e5?w=400',
          unitPrice: 250,
          discountPrice: 230,
          availableQuantity: 20,
          deliveryCharge: 12,
          categoryId: '1',
          isFlashSale: true,
          rating: 4.5,
          reviewCount: 25,
        ),
        ProductModel(
          id: '2',
          name: 'Langra Mango',
          description: 'Premium quality Langra mango',
          imageUrl: 'https://images.unsplash.com/photo-1605027990121-cbae0f43b5e5?w=400',
          unitPrice: 300,
          discountPrice: 280,
          availableQuantity: 15,
          deliveryCharge: 15,
          categoryId: '1',
          isFlashSale: false,
          rating: 4.8,
          reviewCount: 30,
        ),
        ProductModel(
          id: '3',
          name: 'Himsagar Mango',
          description: 'Sweet and juicy Himsagar variety',
          imageUrl: 'https://images.unsplash.com/photo-1605027990121-cbae0f43b5e5?w=400',
          unitPrice: 280,
          availableQuantity: 25,
          deliveryCharge: 12,
          categoryId: '1',
          isFlashSale: false,
          rating: 4.6,
          reviewCount: 18,
        ),
        // Category 2 - Jersey
        ProductModel(
          id: '4',
          name: 'Premium Plant Jersey',
          description: 'High quality plant protection jersey',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          unitPrice: 150,
          discountPrice: 120,
          availableQuantity: 50,
          deliveryCharge: 10,
          categoryId: '2',
          isFlashSale: true,
          rating: 4.3,
          reviewCount: 12,
        ),
        ProductModel(
          id: '5',
          name: 'Garden Jersey Set',
          description: 'Complete set of garden jerseys',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          unitPrice: 500,
          discountPrice: 450,
          availableQuantity: 30,
          deliveryCharge: 20,
          categoryId: '2',
          isFlashSale: false,
          rating: 4.7,
          reviewCount: 22,
        ),
        // Category 3 - বাংলাদেশ
        ProductModel(
          id: '6',
          name: 'বাংলাদেশি গোলাপ',
          description: 'Beautiful Bangladeshi roses',
          imageUrl: 'https://images.unsplash.com/photo-1518621012428-9918b7039c3d?w=400',
          unitPrice: 200,
          discountPrice: 180,
          availableQuantity: 40,
          deliveryCharge: 15,
          categoryId: '3',
          isFlashSale: true,
          rating: 4.9,
          reviewCount: 35,
        ),
        ProductModel(
          id: '7',
          name: 'বাংলাদেশি গাঁদা',
          description: 'Traditional marigold flowers',
          imageUrl: 'https://images.unsplash.com/photo-1518621012428-9918b7039c3d?w=400',
          unitPrice: 120,
          availableQuantity: 60,
          deliveryCharge: 10,
          categoryId: '3',
          isFlashSale: false,
          rating: 4.4,
          reviewCount: 20,
        ),
        // Category 4 - mx ope
        ProductModel(
          id: '8',
          name: 'Mixed Plant Seeds',
          description: 'Variety pack of plant seeds',
          imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400',
          unitPrice: 100,
          discountPrice: 80,
          availableQuantity: 100,
          deliveryCharge: 8,
          categoryId: '4',
          isFlashSale: true,
          rating: 4.2,
          reviewCount: 15,
        ),
        ProductModel(
          id: '9',
          name: 'Organic Fertilizer',
          description: 'Natural organic plant fertilizer',
          imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400',
          unitPrice: 350,
          discountPrice: 320,
          availableQuantity: 45,
          deliveryCharge: 18,
          categoryId: '4',
          isFlashSale: false,
          rating: 4.6,
          reviewCount: 28,
        ),
        // Category 5 - mx ope k...
        ProductModel(
          id: '10',
          name: 'Garden Tools Set',
          description: 'Complete gardening tools collection',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          unitPrice: 800,
          discountPrice: 700,
          availableQuantity: 20,
          deliveryCharge: 25,
          categoryId: '5',
          isFlashSale: true,
          rating: 4.8,
          reviewCount: 40,
        ),
        ProductModel(
          id: '11',
          name: 'Watering Can',
          description: 'Premium quality watering can',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          unitPrice: 250,
          availableQuantity: 35,
          deliveryCharge: 12,
          categoryId: '5',
          isFlashSale: false,
          rating: 4.5,
          reviewCount: 19,
        ),
        // Category 6 - Banglade...
        ProductModel(
          id: '12',
          name: 'Bangladeshi Bonsai',
          description: 'Beautiful bonsai tree',
          imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400',
          unitPrice: 1200,
          discountPrice: 1000,
          availableQuantity: 10,
          deliveryCharge: 30,
          categoryId: '6',
          isFlashSale: true,
          rating: 5.0,
          reviewCount: 12,
        ),
        ProductModel(
          id: '13',
          name: 'Indoor Plant Collection',
          description: 'Set of indoor decorative plants',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
          unitPrice: 600,
          discountPrice: 550,
          availableQuantity: 25,
          deliveryCharge: 20,
          categoryId: '6',
          isFlashSale: false,
          rating: 4.7,
          reviewCount: 33,
        ),
      ];

      _flashSaleProducts = _products.where((p) => p.isFlashSale).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data with better images
      _categories = [
        CategoryModel(
          id: '1',
          name: 'Mango',
          imageUrl: 'https://images.unsplash.com/photo-1605027990121-cbae0f43b5e5?w=200',
          description: 'Fresh mango varieties',
          productCount: 3,
        ),
        CategoryModel(
          id: '2',
          name: 'Jersey',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=200',
          description: 'Plant protection jerseys',
          productCount: 2,
        ),
        CategoryModel(
          id: '3',
          name: 'বাংলাদেশ',
          imageUrl: 'https://images.unsplash.com/photo-1518621012428-9918b7039c3d?w=200',
          description: 'Traditional Bangladeshi flowers',
          productCount: 2,
        ),
        CategoryModel(
          id: '4',
          name: 'Seeds & Fertilizer',
          imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=200',
          description: 'Plant seeds and fertilizers',
          productCount: 2,
        ),
        CategoryModel(
          id: '5',
          name: 'Garden Tools',
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=200',
          description: 'Essential gardening tools',
          productCount: 2,
        ),
        CategoryModel(
          id: '6',
          name: 'Decorative Plants',
          imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=200',
          description: 'Indoor and decorative plants',
          productCount: 2,
        ),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
