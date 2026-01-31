import '../../core/interfaces/base_model.dart';

class UserModel implements BaseModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isEmailVerified;
  final String status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? mobile;
  final String? profileImage;
  final String? avatarId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isEmailVerified,
    required this.status,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.mobile,
    this.profileImage,
    this.avatarId,
  });

  // Getter for backward compatibility
  String get fullName => name;

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'status': status,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mobile': mobile,
      'profileImage': profileImage,
      'avatarId': avatarId,
    };
  }

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJsonMap(json);
  }

  // API: GET {{baseUrl}}/users/profile → data: _id, name, emailOrPhone, role, status, avatarId{_id,name,imageUrl}, profilePicture
  static UserModel fromJsonMap(Map<String, dynamic> json) {
    final profilePicture = json['profilePicture'];
    final avatarIdObj = json['avatarId'];
    String? avatarId;
    String? avatarImageUrl;
    if (avatarIdObj is Map<String, dynamic>) {
      avatarId = avatarIdObj['_id']?.toString();
      avatarImageUrl = avatarIdObj['imageUrl'] as String?;
    }
    final profileImage = profilePicture ?? avatarImageUrl ?? json['profileImage'];

    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? json['emailOrPhone'] ?? '',
      role: json['role'] ?? 'user',
      isEmailVerified: json['isEmailVerified'] ?? false,
      status: json['status'] ?? 'active',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      mobile: json['phone'] ?? json['mobile'],
      profileImage: profileImage is String ? profileImage : null,
      avatarId: avatarId,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isEmailVerified,
    String? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mobile,
    String? profileImage,
    String? avatarId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mobile: mobile ?? this.mobile,
      profileImage: profileImage ?? this.profileImage,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}
