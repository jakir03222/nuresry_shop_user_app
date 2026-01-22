import '../../core/interfaces/base_model.dart';

class FlashSaleModel implements BaseModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final String discountType;
  final int discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<String> productIds;
  final bool featured;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FlashSaleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.productIds,
    required this.featured,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  // Check if flash sale is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Get discount text
  String get discountText {
    if (discountType == 'percentage') {
      return '$discountValue% OFF';
    }
    return '${discountValue}৳ OFF';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'image': image,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'productIds': productIds,
      'featured': featured,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  FlashSaleModel fromJson(Map<String, dynamic> json) {
    return FlashSaleModel.fromJsonMap(json);
  }

  static FlashSaleModel fromJsonMap(Map<String, dynamic> json) {
    return FlashSaleModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toInt(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      productIds: json['productIds'] != null
          ? List<String>.from(json['productIds'])
          : [],
      featured: json['featured'] ?? false,
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  FlashSaleModel copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? discountType,
    int? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<String>? productIds,
    bool? featured,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashSaleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      productIds: productIds ?? this.productIds,
      featured: featured ?? this.featured,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
