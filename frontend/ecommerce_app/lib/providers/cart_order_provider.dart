import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/models/order_model.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';

/// Cart items provider - fetched from server, with local refresh.
class CartNotifier extends StateNotifier<AsyncValue<List<CartItemModel>>> {
  final Ref ref;

  CartNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getCart();
      final items =
          data.map((item) => CartItemModel.fromJson(item)).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.addToCart(productId, quantity: quantity);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateCartItem(itemId, quantity);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.removeFromCart(itemId);
      await loadCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    final api = ref.read(apiServiceProvider);
    final data = await api.createOrderFromCart({
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
    });
    final order = OrderModel.fromJson(data);
    // Refresh cart (should be empty after order)
    await loadCart();
    // Refresh orders
    ref.invalidate(ordersProvider);
    return order;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemModel>>>((ref) {
  return CartNotifier(ref);
});

/// Cart item count.
final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

/// Cart subtotal.
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.maybeWhen(
    data: (items) => items.fold(0.0, (sum, item) => sum + item.totalPrice),
    orElse: () => 0.0,
  );
});

/// User orders.
final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getOrders();
  return data.map((o) => OrderModel.fromJson(o)).toList();
});

/// Single order detail.
final orderDetailProvider =
    FutureProvider.family<OrderModel, int>((ref, orderId) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getOrder(orderId);
  return OrderModel.fromJson(data);
});
