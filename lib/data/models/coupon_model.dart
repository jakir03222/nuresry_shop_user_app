import '../../core/interfaces/base_model.dart';

class CouponModel implements BaseModel {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final DateTime validFrom;
  final DateTime validUntil;
  final int currentUses;
  final bool isActive;
  final int? maxUses;
  final double? minOrderAmount;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validUntil,
    required this.currentUses,
    required this.isActive,
    this.maxUses,
    this.minOrderAmount,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'currentUses': currentUses,
      'isActive': isActive,
      'maxUses': maxUses,
      'minOrderAmount': minOrderAmount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  CouponModel fromJson(Map<String, dynamic> json) {
    return CouponModel.fromJsonMap(json);
  }

  static CouponModel fromJsonMap(Map<String, dynamic> json) {
    return CouponModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      validFrom: DateTime.parse(json['validFrom']),
      validUntil: DateTime.parse(json['validUntil']),
      currentUses: json['currentUses'] ?? 0,
      isActive: json['isActive'] ?? true,
      maxUses: json['maxUses'],
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isStarted => DateTime.now().isAfter(validFrom);
  bool get isValid => isActive && !isExpired && isStarted;
}
