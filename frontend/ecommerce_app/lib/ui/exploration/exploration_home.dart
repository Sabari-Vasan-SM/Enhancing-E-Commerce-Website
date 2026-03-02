import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/product_provider.dart';
import 'package:ecommerce_app/providers/cart_order_provider.dart';
import 'package:ecommerce_app/models/product_model.dart';

/// Flipkart-style home page — responsive for desktop & mobile.
class ExplorationHome extends ConsumerStatefulWidget {
  const ExplorationHome({super.key});

  @override
  ConsumerState<ExplorationHome> createState() => _ExplorationHomeState();
}

class _ExplorationHomeState extends ConsumerState<ExplorationHome> {
  final _searchCtrl = TextEditingController();
  final _bannerPageCtrl = PageController();
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _currentBannerPage = (_currentBannerPage + 1) % 4;
      if (_bannerPageCtrl.hasClients) {
        _bannerPageCtrl.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(query.trim())}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredProductsProvider);
    final personalized = ref.watch(personalizedProductsProvider);
    final saleProducts = ref.watch(saleProductsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;
    final isTablet = screenWidth > 700 && screenWidth <= 1100;
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(personalizedProductsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(saleProductsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ───── FLIPKART-STYLE APP BAR ─────
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: isDesktop ? 64 : 56,
              backgroundColor: const Color(0xFF2874F0),
              title: isDesktop
                  ? Row(
                      children: [
                        const Text('ShopEasy',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                                color: Colors.white)),
                        const SizedBox(width: 24),
                        // Desktop search bar
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 40,
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: TextField(
                              controller: _searchCtrl,
                              onSubmitted: _onSearch,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText:
                                    'Search for products, brands and more',
                                hintStyle: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                                prefixIcon: const Icon(Icons.search,
                                    color: Color(0xFF2874F0)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.go('/profile'),
                          icon: const Icon(Icons.person, color: Colors.white),
                          label: const Text('Profile',
                              style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Badge(
                            isLabelVisible: cartCount > 0,
                            label: Text('$cartCount'),
                            child: const Icon(Icons.shopping_cart,
                                color: Colors.white),
                          ),
                          onPressed: () => context.go('/cart'),
                        ),
                      ],
                    )
                  : const Text('ShopEasy',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white)),
              actions: isDesktop
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => context.push('/search'),
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: cartCount > 0,
                          label: Text('$cartCount'),
                          child: const Icon(Icons.shopping_cart,
                              color: Colors.white),
                        ),
                        onPressed: () => context.go('/cart'),
                      ),
                    ],
            ),

            // ───── MOBILE SEARCH BAR ─────
            if (!isDesktop)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: Color(0xFF2874F0), size: 22),
                          const SizedBox(width: 10),
                          Text('Search for products, brands...',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ───── CATEGORY STRIP ─────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                child: categories.when(
                  loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(),
                  data: (cats) => SizedBox(
                    height: isDesktop ? 110 : 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 8, vertical: 8),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        final cat = cats[index];
                        return GestureDetector(
                          onTap: () => context.push(
                              '/category/${cat.id}?name=${Uri.encodeComponent(cat.name)}'),
                          child: Container(
                            width: isDesktop ? 110 : 80,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: isDesktop ? 30 : 24,
                                  backgroundColor:
                                      const Color(0xFF2874F0).withValues(alpha: 0.1),
                                  child: Icon(_getCategoryIcon(cat.name),
                                      color: const Color(0xFF2874F0),
                                      size: isDesktop ? 28 : 22),
                                ),
                                const SizedBox(height: 6),
                                Text(cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: isDesktop ? 13 : 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ───── AUTO-CAROUSEL BANNERS ─────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                height: isDesktop ? 280 : 160,
                child: Stack(
                  children: [
                    PageView(
                      controller: _bannerPageCtrl,
                      onPageChanged: (i) => setState(() => _currentBannerPage = i),
                      children: _buildBannerItems(isDesktop),
                    ),
                    // Dot indicators
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentBannerPage == i ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _currentBannerPage == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ───── DEALS OF THE DAY ─────
            SliverToBoxAdapter(
              child: _SectionContainer(
                title: 'Deals of the Day',
                icon: Icons.flash_on,
                iconColor: Colors.red,
                trailing: TextButton(
                  onPressed: () =>
                      context.push('/search?q='),
                  child: const Text('VIEW ALL'),
                ),
                child: saleProducts.when(
                  loading: () => const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 50),
                  data: (products) => SizedBox(
                    height: isDesktop ? 320 : 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 8),
                      itemCount: products.length.clamp(0, 12),
                      itemBuilder: (context, index) => _ProductTile(
                        product: products[index],
                        width: isDesktop ? 200 : 150,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ───── FEATURED PRODUCTS ─────
            SliverToBoxAdapter(
              child: _SectionContainer(
                title: 'Featured Products',
                icon: Icons.star,
                iconColor: Colors.amber,
                trailing: TextButton(
                  onPressed: () => context.push('/search?q='),
                  child: const Text('VIEW ALL'),
                ),
                child: featured.when(
                  loading: () => const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 50),
                  data: (products) => SizedBox(
                    height: isDesktop ? 320 : 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 8),
                      itemCount: products.length.clamp(0, 12),
                      itemBuilder: (context, index) => _ProductTile(
                        product: products[index],
                        width: isDesktop ? 200 : 150,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ───── SUGGESTED FOR YOU ─────
            SliverToBoxAdapter(
              child: _SectionContainer(
                title: 'Suggested For You',
                icon: Icons.recommend,
                iconColor: const Color(0xFF2874F0),
                child: personalized.when(
                  loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 50),
                  data: (rec) {
                    final cols = isDesktop
                        ? 5
                        : isTablet
                            ? 3
                            : 2;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 8),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: isDesktop ? 0.72 : 0.62,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: rec.products.length.clamp(0, 15),
                        itemBuilder: (context, index) => _ProductTile(
                          product: rec.products[index],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBannerItems(bool isDesktop) {
    final banners = [
      _BannerData(
        'Super Sale',
        'Up to 70% Off on Electronics',
        const Color(0xFF2874F0),
        const Color(0xFF1565C0),
        Icons.devices,
        () => context.push('/category/1?name=Electronics'),
      ),
      _BannerData(
        'Fashion Week',
        'Trending Styles at Best Prices',
        const Color(0xFFE91E63),
        const Color(0xFFC2185B),
        Icons.checkroom,
        () => context.push('/category/2?name=Fashion'),
      ),
      _BannerData(
        'Home Essentials',
        'Upgrade Your Space — 40% Off',
        const Color(0xFF4CAF50),
        const Color(0xFF2E7D32),
        Icons.home,
        () => context.push('/category/3?name=Home+%26+Kitchen'),
      ),
      _BannerData(
        'Fitness Deals',
        'Sports Gear Starting ₹499',
        const Color(0xFFFF5722),
        const Color(0xFFD84315),
        Icons.fitness_center,
        () => context.push('/category/5?name=Sports+%26+Fitness'),
      ),
    ];
    return banners.map((b) {
      return GestureDetector(
        onTap: b.onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [b.color1, b.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: isDesktop ? 80 : 20,
                top: 0,
                bottom: 0,
                child: Icon(b.icon,
                    size: isDesktop ? 180 : 100,
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 36 : 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(b.subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: isDesktop ? 18 : 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('SHOP NOW',
                          style: TextStyle(
                              color: b.color1,
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 14 : 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'home & kitchen':
        return Icons.home;
      case 'books':
        return Icons.menu_book;
      case 'sports & fitness':
        return Icons.fitness_center;
      case 'beauty & personal care':
        return Icons.face;
      case 'toys & games':
        return Icons.toys;
      case 'groceries':
        return Icons.local_grocery_store;
      default:
        return Icons.category;
    }
  }
}

// ───── Banner data class ─────
class _BannerData {
  final String title, subtitle;
  final Color color1, color2;
  final IconData icon;
  final VoidCallback onTap;
  const _BannerData(
      this.title, this.subtitle, this.color1, this.color2, this.icon, this.onTap);
}

// ───── Section container (Flipkart-style white card with title) ─────
class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final Widget child;
  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ───── Product tile (Flipkart-style) ─────
class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final double? width;
  const _ProductTile({required this.product, this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey)),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(product.formattedDiscount,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Info – compact to prevent overflow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              child: Text(product.formattedPrice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
