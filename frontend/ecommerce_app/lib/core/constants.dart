/// API and App-wide constants.
class AppConstants {
  static const String appName = 'Personalized E-Commerce';

  // API
  static const String baseUrl = 'http://localhost:8000';
  static const String apiPrefix = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiPrefix';
  static const String wsBaseUrl = 'ws://localhost:8000/ws';

  // Endpoints
  static const String registerUrl = '$apiBaseUrl/auth/register';
  static const String loginUrl = '$apiBaseUrl/auth/login';
  static const String profileUrl = '$apiBaseUrl/auth/me';
  static const String userTypeUrl = '$apiBaseUrl/auth/user-type';
  static const String reclassifyUrl = '$apiBaseUrl/auth/reclassify';
  static const String productsUrl = '$apiBaseUrl/products';
  static const String personalizedUrl = '$apiBaseUrl/products/personalized';
  static const String categoriesUrl = '$apiBaseUrl/products/categories';
  static const String brandsUrl = '$apiBaseUrl/products/brands';
  static const String behaviorUrl = '$apiBaseUrl/behavior/track';
  static const String behaviorBatchUrl = '$apiBaseUrl/behavior/track/batch';
  static const String productViewUrl = '$apiBaseUrl/behavior/product-view';
  static const String searchBehaviorUrl = '$apiBaseUrl/behavior/search';
  static const String analyticsUrl = '$apiBaseUrl/behavior/analytics';
  static const String cartUrl = '$apiBaseUrl/cart';
  static const String wishlistUrl = '$apiBaseUrl/wishlist';
  static const String ordersUrl = '$apiBaseUrl/orders';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';

  // User types
  static const String typeExploration = 'exploration';
  static const String typeBrand = 'brand';
  static const String typePrice = 'price';
  static const String typeInteraction = 'interaction';
  static const String typeOffer = 'offer';
  static const String typePremium = 'premium';
}
