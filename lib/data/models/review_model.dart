/// Review from GET {{baseUrl}}/reviews/my – data item: _id, userId, productId{_id,name}, rating, reviewText, isPublished, helpfulCount, createdAt, updatedAt
class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int rating;
  final String reviewText;
  final bool isPublished;
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.reviewText,
    required this.isPublished,
    required this.helpfulCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final productIdObj = json['productId'];
    String productId = '';
    String productName = '';
    if (productIdObj is Map<String, dynamic>) {
      productId = productIdObj['_id']?.toString() ?? '';
      productName = productIdObj['name']?.toString() ?? '';
    } else if (productIdObj != null) {
      productId = productIdObj.toString();
    }

    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      productId: productId,
      productName: productName,
      rating: (json['rating'] is int)
          ? json['rating'] as int
          : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      reviewText: json['reviewText']?.toString() ?? '',
      isPublished: json['isPublished'] == true || json['isPublished'] == 1,
      helpfulCount: (json['helpfulCount'] is int)
          ? json['helpfulCount'] as int
          : int.tryParse(json['helpfulCount']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
