import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecommerce_app/core/constants.dart';

/// HTTP API service for all backend communication.
class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ============ AUTH ============

  Future<Map<String, dynamic>> register(
      String email, String username, String password, String? fullName) async {
    final response = await http.post(
      Uri.parse(AppConstants.registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'full_name': fullName,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(AppConstants.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(AppConstants.profileUrl),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserType() async {
    final response = await http.get(
      Uri.parse(AppConstants.userTypeUrl),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> reclassify() async {
    final response = await http.post(
      Uri.parse(AppConstants.reclassifyUrl),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============ PRODUCTS ============

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 20,
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    String? search,
    bool? isOnSale,
    bool? isFeatured,
    bool? isPremium,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final params = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (brandId != null) 'brand_id': brandId.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (search != null) 'search': search,
      if (isOnSale != null) 'is_on_sale': isOnSale.toString(),
      if (isFeatured != null) 'is_featured': isFeatured.toString(),
      if (isPremium != null) 'is_premium': isPremium.toString(),
    };

    final uri =
        Uri.parse(AppConstants.productsUrl).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getPersonalizedProducts(
      {int page = 1, int pageSize = 20}) async {
    final params = {'page': page.toString(), 'page_size': pageSize.toString()};
    final uri = Uri.parse(AppConstants.personalizedUrl)
        .replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProduct(int productId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.productsUrl}/$productId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse(AppConstants.categoriesUrl),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getBrands() async {
    final response = await http.get(
      Uri.parse(AppConstants.brandsUrl),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // ============ BEHAVIOR TRACKING ============

  Future<void> trackBehavior(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse(AppConstants.behaviorUrl),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<void> trackProductView(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse(AppConstants.productViewUrl),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  Future<void> trackSearch(String query, int resultCount) async {
    await http.post(
      Uri.parse(AppConstants.searchBehaviorUrl),
      headers: _headers,
      body: jsonEncode({
        'query': query,
        'results_count': resultCount,
      }),
    );
  }

  // ============ CART ============

  Future<List<dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse(AppConstants.cartUrl),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addToCart(int productId,
      {int quantity = 1}) async {
    final response = await http.post(
      Uri.parse(AppConstants.cartUrl),
      headers: _headers,
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity) async {
    final response = await http.put(
      Uri.parse('${AppConstants.cartUrl}/$itemId'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    return _handleResponse(response);
  }

  Future<void> removeFromCart(int itemId) async {
    await http.delete(
      Uri.parse('${AppConstants.cartUrl}/$itemId'),
      headers: _headers,
    );
  }

  // ============ WISHLIST ============

  Future<List<dynamic>> getWishlist() async {
    final response = await http.get(
      Uri.parse(AppConstants.wishlistUrl),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<void> addToWishlist(int productId) async {
    await http.post(
      Uri.parse(AppConstants.wishlistUrl),
      headers: _headers,
      body: jsonEncode({'product_id': productId}),
    );
  }

  Future<void> removeFromWishlist(int itemId) async {
    await http.delete(
      Uri.parse('${AppConstants.wishlistUrl}/$itemId'),
      headers: _headers,
    );
  }

  // ============ ORDERS ============

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(AppConstants.ordersUrl),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createOrderFromCart(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.ordersUrl}/from-cart'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse(AppConstants.ordersUrl),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getOrder(int orderId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.ordersUrl}/$orderId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============ HELPERS ============

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['detail'] ?? 'Unknown error occurred',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
