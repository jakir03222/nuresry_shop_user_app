import '../../core/interfaces/base_model.dart';

class CarouselModel implements BaseModel {
  final String id;
  final String image;
  final String title;
  final String description;
  final bool isActive;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CarouselModel({
    required this.id,
    required this.image,
    required this.title,
    required this.description,
    required this.isActive,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'image': image,
      'title': title,
      'description': description,
      'isActive': isActive,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  CarouselModel fromJson(Map<String, dynamic> json) {
    return CarouselModel.fromJsonMap(json);
  }

  static CarouselModel fromJsonMap(Map<String, dynamic> json) {
    return CarouselModel(
      id: json['_id'] ?? json['id'] ?? '',
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  CarouselModel copyWith({
    String? id,
    String? image,
    String? title,
    String? description,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarouselModel(
      id: id ?? this.id,
      image: image ?? this.image,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
