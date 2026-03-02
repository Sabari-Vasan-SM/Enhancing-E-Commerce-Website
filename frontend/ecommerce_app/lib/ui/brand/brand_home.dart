import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/ui/shared/widgets.dart';

/// BRAND UI - For brand-loyal users.
class BrandHome extends ConsumerWidget {
  const BrandHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(brandsProvider);
    final personalized = ref.watch(personalizedProductsProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 700 && w <= 1100;
    final cols = isDesktop ? 5 : isTablet ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.loyalty, color: AppTheme.brandColor, size: 24),
            const SizedBox(width: 8),
            const Text('Your Brands'),
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
          ref.invalidate(brandsProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandColor,
                      AppTheme.brandColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Favorite Brands',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Products from brands you love',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.storefront, size: 48, color: Colors.white24),
                  ],
                ),
              ),

              // Brand Slider
              const SectionHeader(title: 'Shop by Brand', color: AppTheme.brandColor),
              brands.when(
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (brandList) => SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: brandList.length,
                    itemBuilder: (context, index) {
                      final brand = brandList[index];
                      return GestureDetector(
                        onTap: () {
                          final api = ref.read(apiServiceProvider);
                          api.trackBehavior({'behavior_type': 'brand_view', 'brand_id': brand.id});
                          context.push('/search?q=${Uri.encodeComponent(brand.name)}');
                        },
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: brand.isPremium
                                      ? Border.all(color: AppTheme.premiumColor, width: 2) : null,
                                ),
                                child: Center(
                                  child: Text(brand.name[0],
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.brandColor)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(brand.name, textAlign: TextAlign.center, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              if (brand.isPremium)
                                const Text('Premium',
                                    style: TextStyle(fontSize: 9, color: AppTheme.premiumColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Brand Products — responsive grid
              SectionHeader(
                title: 'From Your Brands',
                subtitle: 'Curated picks based on your preferences',
                color: AppTheme.brandColor,
                onViewAll: () => context.push('/search?q='),
              ),
              personalized.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const Padding(padding: EdgeInsets.all(16), child: Text('Unable to load recommendations')),
                data: (rec) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: isDesktop ? 0.72 : 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: rec.products.length.clamp(0, 15),
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: rec.products[index],
                      userType: 'brand',
                      onTap: () => context.push('/product/${rec.products[index].id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
