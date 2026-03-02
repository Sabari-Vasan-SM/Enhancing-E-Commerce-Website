import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/cart_order_provider.dart';
import 'package:ecommerce_app/models/order_model.dart';

/// Fully functional cart screen with quantities, totals, and checkout.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final cartCount = ref.watch(cartCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart ($cartCount items)'),
        centerTitle: false,
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading cart: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Your cart is empty',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Browse products and add items to your cart',
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

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _CartItemsList(items: items),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 350,
                    child: _OrderSummaryCard(
                        subtotal: subtotal, itemCount: cartCount),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(child: _CartItemsList(items: items)),
              _OrderSummaryCard(subtotal: subtotal, itemCount: cartCount),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemsList extends ConsumerWidget {
  final List<CartItemModel> items;
  const _CartItemsList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.product.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey)),
                    errorWidget: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(item.product.formattedPrice,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16)),
                      if (item.product.hasDiscount)
                        Row(children: [
                          Text(item.product.formattedOriginalPrice,
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(item.product.formattedDiscount,
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _QtyBtn(
                            icon: Icons.remove,
                            onPressed: item.quantity > 1
                                ? () => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(item.id, item.quantity - 1)
                                : null),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        _QtyBtn(
                            icon: Icons.add,
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(item.id, item.quantity + 1)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.id),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QtyBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: onPressed == null ? Colors.grey[100] : null,
        ),
        child: Icon(icon,
            size: 18, color: onPressed == null ? Colors.grey[400] : null),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final int itemCount;
  const _OrderSummaryCard({required this.subtotal, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final tax = subtotal * 0.18;
    final shipping = subtotal > 500 ? 0.0 : 50.0;
    final total = subtotal + tax + shipping;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Order Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _Row('Subtotal ($itemCount items)',
                '₹${subtotal.toStringAsFixed(0)}'),
            _Row('GST (18%)', '₹${tax.toStringAsFixed(0)}'),
            _Row('Shipping',
                shipping > 0 ? '₹${shipping.toStringAsFixed(0)}' : 'FREE'),
            const Divider(height: 24),
            _Row('Total', '₹${total.toStringAsFixed(0)}',
                isBold: true, fontSize: 18),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: itemCount > 0 ? () => context.push('/checkout') : null,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Proceed to Checkout',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool isBold;
  final double fontSize;
  const _Row(this.label, this.value, {this.isBold = false, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
