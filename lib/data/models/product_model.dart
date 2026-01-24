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
    final price = (json['price'] ?? json['unitPrice'] ?? 0).toDouble();
    final discount = (json['discount'] ?? 0).toDouble();
    final discountType = json['discountType'] ?? 'percentage';
    
    double? discountPrice;
    if (json['discountPrice'] != null) {
      discountPrice = (json['discountPrice'] as num).toDouble();
    } else if (discount > 0) {
      if (discountType == 'fixed') {
        discountPrice = price - discount;
      } else {
        discountPrice = price * (1 - discount / 100);
      }
    }
    
    // Handle tags - can be array or comma-separated string
    List<String>? tagsList;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = (json['tags'] as List).map((e) => e.toString()).toList();
      } else if (json['tags'] is String) {
        tagsList = (json['tags'] as String).split(',').map((e) => e.trim()).toList();
      }
    }
    
    // Handle images array
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      unitPrice: price,
      discountPrice: discountPrice,
      availableQuantity: json['quantity'] ?? json['availableQuantity'] ?? json['stock'] ?? 0,
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? json['category'] ?? '',
      isFlashSale: json['isFlashSale'] ?? false,
      flashSaleEndDate: json['flashSaleEndDate'] != null
          ? DateTime.parse(json['flashSaleEndDate'])
          : null,
      rating: json['ratingAverage'] != null 
          ? (json['ratingAverage'] as num).toDouble() 
          : (json['rating'] != null ? (json['rating'] as num).toDouble() : null),
      reviewCount: json['ratingCount'] ?? json['reviewCount'],
      sku: json['sku'],
      brand: json['brand'],
      tags: tagsList,
      images: imagesList,
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
    );
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
