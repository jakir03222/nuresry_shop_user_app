class PaymentMethodModel {
  final String id;
  final String methodName;
  final String accountNumber;
  final String? accountName;
  final String? accountType;
  final String? description;
  final String? instructions;
  final bool isActive;
  final int displayOrder;

  PaymentMethodModel({
    required this.id,
    required this.methodName,
    required this.accountNumber,
    this.accountName,
    this.accountType,
    this.description,
    this.instructions,
    required this.isActive,
    required this.displayOrder,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['_id'] as String? ?? '',
      methodName: json['methodName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountName: json['accountName'] as String?,
      accountType: json['accountType'] as String?,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'methodName': methodName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'accountType': accountType,
      'description': description,
      'instructions': instructions,
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }
}
