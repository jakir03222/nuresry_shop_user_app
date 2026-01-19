import '../../core/interfaces/base_model.dart';

class CategoryModel implements BaseModel {
  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final int? productCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description,
    this.productCount,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'productCount': productCount,
    };
  }

  @override
  CategoryModel fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'],
      productCount: json['productCount'],
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? description,
    int? productCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      productCount: productCount ?? this.productCount,
    );
  }
}
