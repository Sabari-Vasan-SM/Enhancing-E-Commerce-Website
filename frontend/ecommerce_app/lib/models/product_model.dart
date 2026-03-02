/// Product model matching backend schema.
class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final double price;
  final double? originalPrice;
  final double discountPercentage;
  final int categoryId;
  final int? brandId;
  final List<String> images;
  final List<String> tags;
  final double avgRating;
  final int reviewCount;
  final bool isFeatured;
  final bool isOnSale;
  final bool isPremium;
  final bool isNewArrival;
  final int stockQuantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.price,
    this.originalPrice,
    this.discountPercentage = 0.0,
    required this.categoryId,
    this.brandId,
    this.images = const [],
    this.tags = const [],
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.isOnSale = false,
    this.isPremium = false,
    this.isNewArrival = false,
    this.stockQuantity = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      description: json['description'],
      shortDescription: json['short_description'],
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      discountPercentage: (json['discount_percentage'] ?? 0).toDouble(),
      categoryId: json['category_id'] ?? 0,
      brandId: json['brand_id'],
      images: List<String>.from(json['images'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      isOnSale: json['is_on_sale'] ?? false,
      isPremium: json['is_premium'] ?? false,
      isNewArrival: json['is_new_arrival'] ?? false,
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }

  bool get hasDiscount => discountPercentage > 0 || (originalPrice != null && originalPrice! > price);

  double get savingsAmount {
    if (originalPrice != null && originalPrice! > price) {
      return originalPrice! - price;
    }
    return 0;
  }

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedOriginalPrice =>
      originalPrice != null ? '₹${originalPrice!.toStringAsFixed(0)}' : '';
  String get formattedDiscount => '${discountPercentage.toStringAsFixed(0)}% OFF';
  String get imageUrl => images.isNotEmpty ? images.first : 'https://placeholder.com/product.jpg';
}

/// Category model
class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Brand model
class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final bool isPremium;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.isPremium = false,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      isPremium: json['is_premium'] ?? false,
    );
  }
}

/// Recommendation response
class RecommendationResponse {
  final String userType;
  final List<ProductModel> products;
  final String reason;
  final Map<String, dynamic> personalization;

  RecommendationResponse({
    required this.userType,
    required this.products,
    required this.reason,
    this.personalization = const {},
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      userType: json['user_type'] ?? 'exploration',
      products: (json['recommended_products'] as List? ?? [])
          .map((p) => ProductModel.fromJson(p))
          .toList(),
      reason: json['reason'] ?? '',
      personalization: Map<String, dynamic>.from(json['personalization_applied'] ?? {}),
    );
  }
}
