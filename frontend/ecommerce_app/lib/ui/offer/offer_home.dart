import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';
import 'package:ecommerce_app/ui/shared/widgets.dart';

/// OFFER UI - For deal-seekers and offer hunters.
class OfferHome extends ConsumerStatefulWidget {
  const OfferHome({super.key});

  @override
  ConsumerState<OfferHome> createState() => _OfferHomeState();
}

class _OfferHomeState extends ConsumerState<OfferHome> {
  late Timer _timer;
  Duration _flashSaleTimeLeft = const Duration(hours: 5, minutes: 32, seconds: 17);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_flashSaleTimeLeft.inSeconds > 0) {
        setState(() { _flashSaleTimeLeft -= const Duration(seconds: 1); });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Icon(Icons.local_offer, color: AppTheme.offerColor, size: 24),
            const SizedBox(width: 8),
            const Text('Offers & Deals'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
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
              // Flash Sale Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4500), Color(0xFFFF6347)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on, color: Colors.yellow, size: 28),
                        SizedBox(width: 8),
                        Text('FLASH SALE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(width: 8),
                        Icon(Icons.flash_on, color: Colors.yellow, size: 28),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Up to 70% OFF', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _timerBox(_flashSaleTimeLeft.inHours.toString().padLeft(2, '0'), 'HRS'),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                        _timerBox((_flashSaleTimeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'MIN'),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                        _timerBox((_flashSaleTimeLeft.inSeconds % 60).toString().padLeft(2, '0'), 'SEC'),
                      ],
                    ),
                  ],
                ),
              ),

              // Offer Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _offerChip('🔥 50% OFF', Colors.red),
                    _offerChip('🎁 Buy 1 Get 1', Colors.purple),
                    _offerChip('🚚 Free Delivery', Colors.blue),
                    _offerChip('💳 Bank Offers', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deal Products — horizontal
              SectionHeader(
                title: 'Today\'s Best Deals 🏷️',
                subtitle: 'Limited time offers',
                color: AppTheme.offerColor,
                onViewAll: () => context.push('/search?q='),
              ),
              saleProducts.when(
                loading: () => const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (products) => SizedBox(
                  height: isDesktop ? 310 : 290,
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
                            ProductCard(product: product, userType: 'offer',
                                onTap: () => context.push('/product/${product.id}')),
                            Positioned(
                              top: 8, left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer, color: Colors.white, size: 12),
                                    SizedBox(width: 2),
                                    Text('Limited', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
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

              // More Deals — responsive grid
              SectionHeader(
                title: 'More Offers For You',
                subtitle: 'Personalized deals',
                color: AppTheme.offerColor,
                onViewAll: () => context.push('/search?q='),
              ),
              personalized.when(
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(),
                data: (rec) {
                  if (isDesktop || isTablet) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        childAspectRatio: isDesktop ? 0.72 : 0.65,
                        crossAxisSpacing: 12, mainAxisSpacing: 12,
                      ),
                      itemCount: rec.products.length.clamp(0, 15),
                      itemBuilder: (context, index) => ProductCard(
                        product: rec.products[index], userType: 'offer',
                        onTap: () => context.push('/product/${rec.products[index].id}'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rec.products.length.clamp(0, 8),
                    itemBuilder: (context, index) => _buildDealCard(context, rec.products[index]),
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

  Widget _timerBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _offerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildDealCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.offerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.local_offer, color: AppTheme.offerColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(product.formattedPrice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(product.formattedOriginalPrice,
                              style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (product.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF4500), Color(0xFFFF6347)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(product.formattedDiscount,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
