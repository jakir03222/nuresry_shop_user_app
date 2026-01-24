/// Embedded address in order response (street, city, postalCode, country only).
class OrderAddress {
  final String street;
  final String city;
  final String postalCode;
  final String country;

  OrderAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory OrderAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return OrderAddress(
        street: '',
        city: '',
        postalCode: '',
        country: '',
      );
    }
    return OrderAddress(
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  String get fullAddress => '$street, $city, $postalCode, $country';
}

/// Order line item.
class OrderItem {
  final String? id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double total;

  OrderItem({
    this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['_id'] as String?,
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0) as int,
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

/// Order model for order history.
class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final OrderAddress shippingAddress;
  final OrderAddress? billingAddress;
  final List<OrderItem> items;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final double subtotal;
  final double tax;
  final double shippingCost;
  final double total;
  final double discountAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.shippingAddress,
    this.billingAddress,
    required this.items,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.shippingCost,
    required this.total,
    required this.discountAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['_id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      shippingAddress: OrderAddress.fromJson(
        json['shippingAddress'] as Map<String, dynamic>?,
      ),
      billingAddress: json['billingAddress'] != null
          ? OrderAddress.fromJson(
              json['billingAddress'] as Map<String, dynamic>?,
            )
          : null,
      items: itemsList
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderStatus: json['orderStatus'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
