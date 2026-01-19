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
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      discountPrice: json['discountPrice'] != null
          ? (json['discountPrice'] as num).toDouble()
          : null,
      availableQuantity: json['availableQuantity'] ?? 0,
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      isFlashSale: json['isFlashSale'] ?? false,
      flashSaleEndDate: json['flashSaleEndDate'] != null
          ? DateTime.parse(json['flashSaleEndDate'])
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'],
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
    );
  }
}
