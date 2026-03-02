import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/models/product_model.dart';

class PremiumHome extends ConsumerWidget {
  const PremiumHome({super.key});

  static const _gold = AppTheme.premiumColor;
  static const _bg = AppTheme.premiumBg;
  static const _accent = AppTheme.premiumAccent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(premiumProductsProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 700 && w <= 1100;
    final cols = isDesktop ? 4 : isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: productsAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: _gold)),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: _gold))),
          data: (products) => CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(child: _buildVipBanner()),
              SliverToBoxAdapter(child: _buildSectionTitle('Exclusive Collection')),
              _buildExclusiveGrid(context, products, cols, isDesktop),
              SliverToBoxAdapter(child: _buildSectionTitle('Premium Picks')),
              _buildPremiumList(context, products, isDesktop),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _bg,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Premium Lounge',
            style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_bg, _accent.withValues(alpha: 0.3)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: Icon(Icons.search, color: _gold), onPressed: () => context.push('/search')),
        IconButton(icon: Icon(Icons.shopping_bag_outlined, color: _gold), onPressed: () => context.go('/cart')),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildVipBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.2), _accent.withValues(alpha: 0.2)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: _gold, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIP Member', style: TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Enjoy exclusive discounts & early access',
                    style: TextStyle(color: _gold.withValues(alpha: 0.7), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: _gold, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _buildExclusiveGrid(BuildContext context, List<ProductModel> products, int cols, bool isDesktop) {
    final exclusive = products.take(cols * 2).toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildExclusiveCard(context, exclusive[index]),
          childCount: exclusive.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 16, crossAxisSpacing: 16,
          childAspectRatio: isDesktop ? 0.75 : 0.72,
        ),
      ),
    );
  }

  Widget _buildExclusiveCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: _gold.withValues(alpha: 0.08),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: _gold.withValues(alpha: 0.08),
                    child: Icon(Icons.diamond, size: 48, color: _gold.withValues(alpha: 0.6)),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _gold, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product.formattedPrice,
                            style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.add, color: _gold, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumList(BuildContext context, List<ProductModel> products, bool isDesktop) {
    final premiumPicks = products.skip(6).take(isDesktop ? 12 : 8).toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildPremiumCard(context, premiumPicks[index]),
        childCount: premiumPicks.length,
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: _gold.withValues(alpha: 0.08),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: _gold.withValues(alpha: 0.08),
                    child: Icon(Icons.shopping_bag, color: _gold.withValues(alpha: 0.5), size: 36),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (product.brandId != null)
                    Text('Brand #${product.brandId}',
                        style: TextStyle(color: _gold.withValues(alpha: 0.5), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(product.formattedPrice,
                          style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_gold, _accent]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Add to Cart',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
