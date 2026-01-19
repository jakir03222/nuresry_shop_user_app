import '../../core/interfaces/base_model.dart';

class UserModel implements BaseModel {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String? profileImage;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    this.profileImage,
    this.createdAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      profileImage: json['profileImage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobile,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
