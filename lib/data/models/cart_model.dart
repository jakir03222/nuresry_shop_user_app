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
    // Handle productId - it can be a full product object or just an ID
    ProductModel product;
    if (json['productId'] is Map<String, dynamic>) {
      // productId is a full product object
      product = ProductModel.fromJsonMap(json['productId'] as Map<String, dynamic>);
    } else {
      // productId is just an ID string, create minimal product
      product = ProductModel.fromJsonMap({'_id': json['productId']});
    }
    
    return CartItemModel(
      id: json['_id'] as String?,
      product: product,
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
    final items = itemsList
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    
    // Calculate totalItems from items count
    final totalItemsCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    // Use 'total' field from API response, fallback to 'subtotal' or 0
    final totalPrice = (json['total'] ?? json['subtotal'] ?? 0).toDouble();
    
    return CartModel(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      items: items,
      totalPrice: totalPrice,
      totalItems: totalItemsCount,
    );
  }
}
