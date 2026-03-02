import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/providers/cart_order_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/ui/shared/widgets.dart';

/// INTERACTION UI - For highly engaged users.
class InteractionHome extends ConsumerWidget {
  const InteractionHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalized = ref.watch(personalizedProductsProvider);
    final featured = ref.watch(featuredProductsProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 700 && w <= 1100;
    final cols = isDesktop ? 5 : isTablet ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.touch_app, color: AppTheme.interactionColor, size: 24),
            const SizedBox(width: 8),
            const Text('For You'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalizedProductsProvider);
          ref.invalidate(featuredProductsProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickAction(context, Icons.history, 'Recently\nViewed', ref),
                    _quickAction(context, Icons.favorite, 'Wishlist', ref),
                    _quickAction(context, Icons.local_offer, 'Deals', ref),
                    _quickAction(context, Icons.star, 'Top Rated', ref),
                  ],
                ),
              ),

              // Activity Summary Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.interactionColor.withValues(alpha: 0.15),
                      AppTheme.interactionColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.interactionColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Curated just for you!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Based on your browsing & interactions',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personalized Picks - horizontal scroll with quick add
              SectionHeader(
                title: 'Picked For You ⚡',
                subtitle: 'Based on your activity',
                color: AppTheme.interactionColor,
                onViewAll: () => context.push('/search?q='),
              ),
              personalized.when(
                loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (rec) => SizedBox(
                  height: isDesktop ? 330 : 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: rec.products.length.clamp(0, 12),
                    itemBuilder: (context, index) {
                      final product = rec.products[index];
                      return SizedBox(
                        width: isDesktop ? 200 : 170,
                        child: Stack(
                          children: [
                            ProductCard(
                              product: product,
                              userType: 'interaction',
                              onTap: () => context.push('/product/${product.id}'),
                            ),
                            Positioned(
                              bottom: 55,
                              right: 8,
                              child: Material(
                                color: AppTheme.interactionColor,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    ref.read(cartProvider.notifier).addToCart(product.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} added to cart'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                                  ),
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

              // Featured grid — responsive
              SectionHeader(
                title: 'Trending Now 🔥',
                subtitle: 'Most popular products',
                color: AppTheme.interactionColor,
                onViewAll: () => context.push('/search?q='),
              ),
              featured.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (products) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: isDesktop ? 0.72 : 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length.clamp(0, 15),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      userType: 'interaction',
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.interactionColor,
        onPressed: () => context.go('/cart'),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/search?q='),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.interactionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.interactionColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
