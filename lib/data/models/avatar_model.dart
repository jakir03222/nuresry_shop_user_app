import '../../core/constants/api_constants.dart';

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

  /// Full URL for display (prepends base URL if relative)
  String get fullImageUrl {
    final url = imageUrl.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['imageUrl'] ?? json['image'] ?? json['url'] ?? '';
    final imageUrl = rawUrl is String ? rawUrl : rawUrl.toString();
    return AvatarModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: imageUrl,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
