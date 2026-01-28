import '../../core/interfaces/base_model.dart';

class CategoryModel implements BaseModel {
  final String id;
  final String title;
  final String image;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? productCount; // Optional, for UI purposes

  CategoryModel({
    required this.id,
    required this.title,
    required this.image,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.productCount,
  });

  // Getter for backward compatibility
  String get name => title;
  String get imageUrl => image;

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'image': image,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  CategoryModel fromJson(Map<String, dynamic> json) {
    return CategoryModel.fromJsonMap(json);
  }

  static CategoryModel fromJsonMap(Map<String, dynamic> json) {
    // Safely parse productCount - handle both int and string types
    int? parseProductCount(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }
    
    return CategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? json['imageUrl']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      productCount: parseProductCount(json['productCount']),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? title,
    String? image,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? productCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
    );
  }
}
