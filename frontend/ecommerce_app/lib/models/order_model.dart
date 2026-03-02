/// Order-related models matching backend schemas.
import 'product_model.dart';

class CartItemModel {
  final int id;
  final int productId;
  final int quantity;
  final ProductModel product;
  final DateTime addedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
    required this.addedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      product: ProductModel.fromJson(json['product']),
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  double get totalPrice => product.price * quantity;
  String get formattedTotal => '₹${totalPrice.toStringAsFixed(0)}';
}

class OrderItemModel {
  final int id;
  final int productId;
  final int quantity;
  final double priceAtPurchase;
  final double discountAtPurchase;
  final double totalPrice;
  final OrderItemProductInfo? product;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.discountAtPurchase,
    required this.totalPrice,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      priceAtPurchase: (json['price_at_purchase'] ?? 0).toDouble(),
      discountAtPurchase: (json['discount_at_purchase'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      product: json['product'] != null
          ? OrderItemProductInfo.fromJson(json['product'])
          : null,
    );
  }

  String get formattedPrice => '₹${priceAtPurchase.toStringAsFixed(0)}';
  String get formattedTotal => '₹${totalPrice.toStringAsFixed(0)}';
}

class OrderItemProductInfo {
  final int id;
  final String name;
  final String slug;
  final double price;
  final List<String> images;
  final int? brandId;

  OrderItemProductInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.images = const [],
    this.brandId,
  });

  factory OrderItemProductInfo.fromJson(Map<String, dynamic> json) {
    return OrderItemProductInfo(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      brandId: json['brand_id'],
    );
  }

  String get imageUrl => images.isNotEmpty
      ? images.first
      : 'https://picsum.photos/seed/product/200/200';
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final double discountAmount;
  final double taxAmount;
  final double shippingAmount;
  final double finalAmount;
  final String? paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic> shippingAddress;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.shippingAmount,
    required this.finalAmount,
    this.paymentMethod,
    required this.paymentStatus,
    this.shippingAddress = const {},
    this.items = const [],
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      shippingAmount: (json['shipping_amount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      shippingAddress:
          Map<String, dynamic>.from(json['shipping_address'] ?? {}),
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItemModel.fromJson(i))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
    );
  }

  String get formattedTotal => '₹${finalAmount.toStringAsFixed(0)}';
  String get formattedSubtotal => '₹${totalAmount.toStringAsFixed(0)}';
  String get formattedTax => '₹${taxAmount.toStringAsFixed(0)}';
  String get formattedShipping =>
      shippingAmount > 0 ? '₹${shippingAmount.toStringAsFixed(0)}' : 'FREE';
  String get formattedDiscount =>
      discountAmount > 0 ? '-₹${discountAmount.toStringAsFixed(0)}' : '₹0';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'returned':
        return 'Returned';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}
