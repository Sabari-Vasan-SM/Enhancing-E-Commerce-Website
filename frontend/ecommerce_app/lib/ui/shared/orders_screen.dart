import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/cart_order_provider.dart';
import 'package:ecommerce_app/models/order_model.dart';

/// My Orders screen - lists all user orders.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Your orders will appear here',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(order.orderNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  _StatusChip(status: order.status, label: order.statusLabel),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Divider(height: 20),
              // Items preview (show first 3 items)
              ...order.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.product != null
                              ? CachedNetworkImage(
                                  imageUrl: item.product!.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image,
                                          size: 20, color: Colors.grey)),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      size: 20, color: Colors.grey)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product?.name ??
                                    'Product #${item.productId}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                  'Qty: ${item.quantity} × ${item.formattedPrice}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        Text(item.formattedTotal,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${order.items.length - 3} more items',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ),
              const Divider(height: 20),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalItems} items',
                      style: TextStyle(color: Colors.grey[600])),
                  Text('Total: ${order.formattedTotal}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status, label;
  const _StatusChip({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
      case 'processing':
        color = Colors.blue;
        break;
      case 'shipped':
        color = Colors.indigo;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
      case 'returned':
      case 'refunded':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Order detail screen.
class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          final dateStr =
              DateFormat('MMM dd, yyyy hh:mm a').format(order.createdAt);
          final addr = order.shippingAddress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.orderNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(dateStr,
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        _StatusChip(
                            status: order.status, label: order.statusLabel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Items
                Text('Items (${order.totalItems})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: item.product != null
                              ? CachedNetworkImage(
                                  imageUrl: item.product!.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image)),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image)),
                        ),
                        title: Text(
                            item.product?.name ?? 'Product #${item.productId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            'Qty: ${item.quantity} × ${item.formattedPrice}'),
                        trailing: Text(item.formattedTotal,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    )),
                const SizedBox(height: 16),

                // Price breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _DetailRow('Subtotal', order.formattedSubtotal),
                        _DetailRow('Discount', order.formattedDiscount),
                        _DetailRow('GST', order.formattedTax),
                        _DetailRow('Shipping', order.formattedShipping),
                        const Divider(),
                        _DetailRow('Total', order.formattedTotal, isBold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Shipping address
                if (addr.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shipping Address',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(addr['name'] ?? ''),
                          Text(
                              '${addr['line1'] ?? ''}, ${addr['line2'] ?? ''}'),
                          Text(
                              '${addr['city'] ?? ''}, ${addr['state'] ?? ''} - ${addr['pincode'] ?? ''}'),
                          if (addr['phone'] != null) Text(addr['phone']),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Payment info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _DetailRow('Method',
                            (order.paymentMethod ?? 'cod').toUpperCase()),
                        _DetailRow('Status', order.paymentStatus.toUpperCase()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
