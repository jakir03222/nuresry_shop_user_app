import '../../core/interfaces/base_model.dart';

class AddressModel implements BaseModel {
  final String id;
  final String userId;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final String phoneNumber;
  final String? label;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
    this.label,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJsonMap(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['userId'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      label: json['label'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'label': label,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  AddressModel fromJson(Map<String, dynamic> json) => AddressModel.fromJsonMap(json);

  String get fullAddress => '$street, $city, $postalCode, $country';

  AddressModel copyWith({
    String? id,
    String? userId,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    String? phoneNumber,
    String? label,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
