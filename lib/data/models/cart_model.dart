import 'product_model.dart';

class CartItemModel {
  final String? id;
  final ProductModel product;
  final int quantity;
  final double price;
  final double total;

  CartItemModel({
    this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['_id'] as String?,
      product: ProductModel.fromJsonMap(json['productId'] is Map ? json['productId'] : {'_id': json['productId']}),
      quantity: (json['quantity'] ?? 0) as int,
      price: (json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }
}

class CartModel {
  final String? id;
  final String? userId;
  final List<CartItemModel> items;
  final double totalPrice;
  final int totalItems;

  CartModel({
    this.id,
    this.userId,
    required this.items,
    required this.totalPrice,
    required this.totalItems,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      items: itemsList
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      totalItems: (json['totalItems'] ?? 0) as int,
    );
  }
}
