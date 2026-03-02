import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';

/// Personalized products for the current user.
final personalizedProductsProvider =
    FutureProvider<RecommendationResponse>((ref) async {
  final api = ref.read(apiServiceProvider);
  // Re-fetch when user type changes
  ref.watch(userTypeProvider);
  final data = await api.getPersonalizedProducts();
  return RecommendationResponse.fromJson(data);
});

/// All products with pagination.
final productsProvider = FutureProvider.family<List<ProductModel>, Map<String, dynamic>>(
    (ref, params) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getProducts(
    page: params['page'] ?? 1,
    pageSize: params['page_size'] ?? 20,
    categoryId: params['category_id'],
    brandId: params['brand_id'],
    search: params['search'],
    isOnSale: params['is_on_sale'],
    sortBy: params['sort_by'] ?? 'created_at',
    sortOrder: params['sort_order'] ?? 'desc',
  );
  return (data['products'] as List)
      .map((p) => ProductModel.fromJson(p))
      .toList();
});

/// Categories list.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getCategories();
  return data.map((c) => CategoryModel.fromJson(c)).toList();
});

/// Brands list.
final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getBrands();
  return data.map((b) => BrandModel.fromJson(b)).toList();
});

/// Featured products.
final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getProducts(isFeatured: true, pageSize: 10);
  return (data['products'] as List)
      .map((p) => ProductModel.fromJson(p))
      .toList();
});

/// Sale products.
final saleProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getProducts(
    isOnSale: true,
    sortBy: 'discount_percentage',
    sortOrder: 'desc',
    pageSize: 20,
  );
  return (data['products'] as List)
      .map((p) => ProductModel.fromJson(p))
      .toList();
});

/// Premium products.
final premiumProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getProducts(
    isPremium: true,
    sortBy: 'avg_rating',
    sortOrder: 'desc',
    pageSize: 20,
  );
  return (data['products'] as List)
      .map((p) => ProductModel.fromJson(p))
      .toList();
});

/// Search results.
final searchResultsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  final api = ref.read(apiServiceProvider);
  // Track search behavior
  final data = await api.getProducts(search: query);
  final products = (data['products'] as List)
      .map((p) => ProductModel.fromJson(p))
      .toList();
  // Track search
  api.trackSearch(query, products.length);
  return products;
});
