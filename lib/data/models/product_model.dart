import 'package:flutter/foundation.dart';
import '../../core/interfaces/base_model.dart';

class ProductModel implements BaseModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double unitPrice;
  final double? discountPrice;
  final int availableQuantity;
  final double deliveryCharge;
  final String categoryId;
  final bool isFlashSale;
  final DateTime? flashSaleEndDate;
  final double? rating;
  final int? reviewCount;
  final String? sku;
  final String? brand;
  final List<String>? tags;
  final List<String>? images;
  final bool isAvailable;
  final bool isFeatured;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.unitPrice,
    this.discountPrice,
    required this.availableQuantity,
    required this.deliveryCharge,
    required this.categoryId,
    this.isFlashSale = false,
    this.flashSaleEndDate,
    this.rating,
    this.reviewCount,
    this.sku,
    this.brand,
    this.tags,
    this.images,
    this.isAvailable = true,
    this.isFeatured = false,
  });

  double get finalPrice => discountPrice ?? unitPrice;
  double get discountPercentage {
    if (discountPrice == null) return 0;
    return ((unitPrice - discountPrice!) / unitPrice) * 100;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'discountPrice': discountPrice,
      'availableQuantity': availableQuantity,
      'deliveryCharge': deliveryCharge,
      'categoryId': categoryId,
      'isFlashSale': isFlashSale,
      'flashSaleEndDate': flashSaleEndDate?.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  @override
  ProductModel fromJson(Map<String, dynamic> json) {
    return ProductModel.fromJsonMap(json);
  }

  static ProductModel fromJsonMap(Map<String, dynamic> json) {
    debugPrint('[ProductModel.fromJsonMap] ========== PARSING PRODUCT ==========');
    debugPrint('[ProductModel.fromJsonMap] Product ID: ${json['_id'] ?? json['id']}');
    debugPrint('[ProductModel.fromJsonMap] Product Name: ${json['name']}');
    
    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      if (value is num) return value.toDouble();
      return defaultValue;
    }
    
    // Helper function to safely convert to int
    int safeToInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      if (value is num) return value.toInt();
      return defaultValue;
    }
    
    final price = safeToDouble(json['price'] ?? json['unitPrice'], 0.0);
    final discount = safeToDouble(json['discount'], 0.0);
    final discountType = json['discountType']?.toString() ?? 'percentage';
    
    debugPrint('[ProductModel.fromJsonMap] Price: $price');
    debugPrint('[ProductModel.fromJsonMap] Discount: $discount');
    debugPrint('[ProductModel.fromJsonMap] Discount Type: $discountType');
    
    double? discountPrice;
    if (json['discountPrice'] != null) {
      discountPrice = safeToDouble(json['discountPrice']);
      debugPrint('[ProductModel.fromJsonMap] Discount Price (from API): $discountPrice');
    } else if (discount > 0) {
      if (discountType == 'fixed') {
        discountPrice = price - discount;
        debugPrint('[ProductModel.fromJsonMap] Discount Price (fixed): $discountPrice');
      } else {
        discountPrice = price * (1 - discount / 100);
        debugPrint('[ProductModel.fromJsonMap] Discount Price (percentage): $discountPrice');
      }
    } else {
      debugPrint('[ProductModel.fromJsonMap] No discount applied');
    }
    
    // Handle tags - can be array or comma-separated string
    List<String>? tagsList;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
      } else if (json['tags'] is String) {
        tagsList = (json['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    
    // Handle images array
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    
    // Safely parse rating
    double? rating;
    if (json['ratingAverage'] != null) {
      rating = safeToDouble(json['ratingAverage']);
    } else if (json['rating'] != null) {
      rating = safeToDouble(json['rating']);
    }
    
    // Safely parse review count
    int? reviewCount;
    if (json['ratingCount'] != null) {
      reviewCount = safeToInt(json['ratingCount']);
    } else if (json['reviewCount'] != null) {
      reviewCount = safeToInt(json['reviewCount']);
    }
    
    final courierCharge = safeToDouble(json['courierCharge'] ?? json['deliveryCharge'], 0.0);
    debugPrint('[ProductModel.fromJsonMap] Courier/Delivery Charge: $courierCharge');
    
    final result = ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      unitPrice: price,
      discountPrice: discountPrice,
      availableQuantity: safeToInt(json['quantity'] ?? json['availableQuantity'] ?? json['stock'], 0),
      deliveryCharge: courierCharge, // Support both courierCharge and deliveryCharge
      categoryId: json['categoryId']?.toString() ?? json['category']?.toString() ?? '',
      isFlashSale: json['isFlashSale'] == true || json['isFlashSale'] == 1,
      flashSaleEndDate: json['flashSaleEndDate'] != null
          ? DateTime.tryParse(json['flashSaleEndDate'].toString())
          : null,
      rating: rating,
      reviewCount: reviewCount,
      sku: json['sku']?.toString(),
      brand: json['brand']?.toString(),
      tags: tagsList,
      images: imagesList,
      isAvailable: json['isAvailable'] != false && json['isAvailable'] != 0,
      isFeatured: json['isFeatured'] == true || json['isFeatured'] == 1,
    );
    
    debugPrint('[ProductModel.fromJsonMap] ✓ Product parsed successfully');
    debugPrint('[ProductModel.fromJsonMap] Final Price: ${result.unitPrice}');
    debugPrint('[ProductModel.fromJsonMap] Discount Price: ${result.discountPrice}');
    debugPrint('[ProductModel.fromJsonMap] Delivery Charge: ${result.deliveryCharge}');
    debugPrint('[ProductModel.fromJsonMap] Quantity: ${result.availableQuantity}');
    debugPrint('[ProductModel.fromJsonMap] Rating: ${result.rating}');
    debugPrint('[ProductModel.fromJsonMap] ========== PARSING COMPLETE ==========');
    
    return result;
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? unitPrice,
    double? discountPrice,
    int? availableQuantity,
    double? deliveryCharge,
    String? categoryId,
    bool? isFlashSale,
    DateTime? flashSaleEndDate,
    double? rating,
    int? reviewCount,
    String? sku,
    String? brand,
    List<String>? tags,
    List<String>? images,
    bool? isAvailable,
    bool? isFeatured,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      categoryId: categoryId ?? this.categoryId,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      flashSaleEndDate: flashSaleEndDate ?? this.flashSaleEndDate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sku: sku ?? this.sku,
      brand: brand ?? this.brand,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
