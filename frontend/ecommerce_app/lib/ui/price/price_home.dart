import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/ui/shared/widgets.dart';

/// PRICE UI - For budget-conscious shoppers.
class PriceHome extends ConsumerWidget {
  const PriceHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalized = ref.watch(personalizedProductsProvider);
    final saleProducts = ref.watch(saleProductsProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 700 && w <= 1100;
    final cols = isDesktop ? 5 : isTablet ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.savings, color: AppTheme.priceColor, size: 24),
            const SizedBox(width: 8),
            const Text('Best Deals'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalizedProductsProvider);
          ref.invalidate(saleProductsProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.priceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.priceColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.priceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.trending_down, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price Drop Alert!',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Products sorted by best value. Save more!',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quick price range chips — now navigate to search with price param
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _priceChip(context, 'Under ₹500', ref),
                    _priceChip(context, 'Under ₹1000', ref),
                    _priceChip(context, 'Under ₹2000', ref),
                    _priceChip(context, 'Under ₹5000', ref),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Best Deals - horizontal
              SectionHeader(
                title: 'Maximum Savings 💰',
                subtitle: 'Products with highest discounts',
                color: AppTheme.priceColor,
                onViewAll: () => context.push('/search?q='),
              ),
              saleProducts.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (products) => SizedBox(
                  height: isDesktop ? 310 : 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: products.length.clamp(0, 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return SizedBox(
                        width: isDesktop ? 200 : 180,
                        child: Stack(
                          children: [
                            ProductCard(
                              product: product,
                              userType: 'price',
                              onTap: () => context.push('/product/${product.id}'),
                            ),
                            if (product.hasDiscount)
                              Positioned(
                                bottom: 75,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.priceColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Save ₹${product.savingsAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // All products sorted by price — responsive grid
              SectionHeader(
                title: 'Best Value Products',
                subtitle: 'Sorted by lowest price',
                color: AppTheme.priceColor,
                onViewAll: () => context.push('/search?q='),
              ),
              personalized.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (rec) {
                  final sorted = List.of(rec.products)
                    ..sort((a, b) => a.price.compareTo(b.price));
                  // Desktop: show grid instead of list for better use of space
                  if (isDesktop || isTablet) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: isDesktop ? 0.72 : 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: sorted.length.clamp(0, 15),
                      itemBuilder: (context, index) => ProductCard(
                        product: sorted[index],
                        userType: 'price',
                        onTap: () => context.push('/product/${sorted[index].id}'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sorted.length.clamp(0, 10),
                    itemBuilder: (context, index) {
                      final product = sorted[index];
                      return _buildPriceCompareCard(context, product);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceChip(BuildContext context, String label, WidgetRef ref) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppTheme.priceColor.withValues(alpha: 0.1),
      side: BorderSide(color: AppTheme.priceColor.withValues(alpha: 0.3)),
      onPressed: () {
        final api = ref.read(apiServiceProvider);
        api.trackBehavior({'behavior_type': 'price_filter', 'filter_type': 'price', 'filter_value': label});
        context.push('/search?q=${Uri.encodeComponent(label)}');
      },
    );
  }

  Widget _buildPriceCompareCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(product.formattedPrice,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.priceColor)),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(product.formattedOriginalPrice,
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 13)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (product.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: Text(product.formattedDiscount,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
