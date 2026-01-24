class ContactModel {
  final String id;
  final String label;
  final String contactType;
  final String contactValue;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactModel({
    required this.id,
    required this.label,
    required this.contactType,
    required this.contactValue,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['_id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      contactType: json['contactType'] as String? ?? '',
      contactValue: json['contactValue'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] ?? 0) as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isPhone =>
      contactType.toLowerCase().contains('phone') ||
      contactType.toLowerCase().contains('telegram') ||
      contactType.toLowerCase().contains('whatsapp');

  bool get isEmail => contactType.toLowerCase().contains('email');
}
