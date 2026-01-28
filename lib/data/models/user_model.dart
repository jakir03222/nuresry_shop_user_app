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
    };
  }

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJsonMap(json);
  }

  // Static factory method for easier usage
  static UserModel fromJsonMap(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
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
      mobile: json['phone'] ?? json['mobile'], // Support both 'phone' and 'mobile' fields
      profileImage: json['profilePicture'] ?? json['profileImage'],
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
    );
  }
}
