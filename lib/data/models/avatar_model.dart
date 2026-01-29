/// Avatar from GET {{baseUrl}}/avatars?page=1&limit=10
class AvatarModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;

  AvatarModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isActive,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
