import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/ui/shared/widgets.dart';

/// INTERACTION UI - For highly engaged users.
///
/// Features:
/// - Quick actions everywhere
/// - Infinite-scroll feel
/// - Recently viewed
/// - Rapid add-to-cart
/// - Activity-driven recommendations
class InteractionHome extends ConsumerWidget {
  const InteractionHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalized = ref.watch(personalizedProductsProvider);
    final featured = ref.watch(featuredProductsProvider);

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
            onPressed: () {
              final api = ref.read(apiServiceProvider);
              api.trackBehavior({'behavior_type': 'search'});
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
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
                    _quickAction(Icons.history, 'Recently\nViewed', ref),
                    _quickAction(Icons.favorite, 'Wishlist', ref),
                    _quickAction(Icons.local_offer, 'Deals', ref),
                    _quickAction(Icons.star, 'Top Rated', ref),
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
                          Text(
                            'Curated just for you!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Based on your browsing & interactions',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Personalized Picks - horizontal scroll with quick add
              const SectionHeader(
                title: 'Picked For You ⚡',
                subtitle: 'Based on your activity',
                color: AppTheme.interactionColor,
              ),
              personalized.when(
                loading: () => const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
                data: (rec) => SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: rec.products.length.clamp(0, 10),
                    itemBuilder: (context, index) {
                      final product = rec.products[index];
                      return SizedBox(
                        width: 170,
                        child: Stack(
                          children: [
                            ProductCard(
                              product: product,
                              userType: 'interaction',
                              onTap: () => context.push('/product/${product.id}'),
                            ),
                            // Quick Add to Cart button
                            Positioned(
                              bottom: 55,
                              right: 8,
                              child: Material(
                                color: AppTheme.interactionColor,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    // Quick add to cart
                                    final api = ref.read(apiServiceProvider);
                                    api.addToCart(product.id, quantity: 1);
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
                                    child: Icon(Icons.add_shopping_cart,
                                        color: Colors.white, size: 18),
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

              // Featured grid with engagement indicators
              const SectionHeader(
                title: 'Trending Now 🔥',
                subtitle: 'Most popular products',
                color: AppTheme.interactionColor,
              ),
              featured.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox(),
                data: (products) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length.clamp(0, 8),
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
      // FAB for quick cart access
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.interactionColor,
        onPressed: () => context.push('/cart'),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final api = ref.read(apiServiceProvider);
        api.trackBehavior({
          'behavior_type': 'quick_action',
          'action': label,
        });
      },
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
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
