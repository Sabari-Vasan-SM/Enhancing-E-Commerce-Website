import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

/// Product detail screen - adapts layout based on user type.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  DateTime? _viewStartTime;

  @override
  void initState() {
    super.initState();
    _viewStartTime = DateTime.now();
    _loadProduct();
  }

  @override
  void dispose() {
    // Track time spent on product
    if (_viewStartTime != null && _product != null) {
      final timeSpent = DateTime.now().difference(_viewStartTime!).inSeconds;
      final api = ref.read(apiServiceProvider);
      api.trackProductView({
        'product_id': _product!.id,
        'time_spent_seconds': timeSpent.toDouble(),
        'source': 'product_detail',
      });
    }
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getProduct(widget.productId);
      setState(() {
        _product = ProductModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = ref.watch(userTypeProvider);
    final accentColor = AppTheme.getAccentColor(userType);
    final isPremium = userType == 'premium';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final product = _product!;

    return Theme(
      data: isPremium ? AppTheme.premiumTheme : Theme.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isPremium ? '' : product.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                final api = ref.read(apiServiceProvider);
                api.addToWishlist(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to wishlist')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                height: 300,
                width: double.infinity,
                color: isPremium ? AppTheme.premiumBg : Colors.grey[100],
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    if (product.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: product.tags.take(4).map((tag) {
                          return Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),

                    // Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isPremium ? 24 : 20,
                        fontWeight: isPremium ? FontWeight.w300 : FontWeight.bold,
                        color: isPremium ? Colors.white : null,
                        letterSpacing: isPremium ? 1 : 0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    if (product.avgRating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < product.avgRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${product.avgRating} (${product.reviewCount} reviews)',
                            style: TextStyle(
                              color: isPremium ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Price section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isPremium
                            ? AppTheme.premiumSurface
                            : accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isPremium ? AppTheme.premiumColor : accentColor,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 12),
                            Text(
                              product.formattedOriginalPrice,
                              style: TextStyle(
                                fontSize: 18,
                                decoration: TextDecoration.lineThrough,
                                color: isPremium ? Colors.white38 : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.formattedDiscount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    if (product.description != null) ...[
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPremium ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isPremium ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stock info
                    Row(
                      children: [
                        Icon(
                          product.stockQuantity > 0
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: product.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.stockQuantity > 0
                              ? 'In Stock (${product.stockQuantity})'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: product.stockQuantity > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom action buttons
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPremium ? AppTheme.premiumSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: accentColor),
                    foregroundColor: accentColor,
                  ),
                  onPressed: () async {
                    final api = ref.read(apiServiceProvider);
                    await api.addToCart(product.id);
                    // Track behavior
                    api.trackBehavior({
                      'behavior_type': 'add_to_cart',
                      'product_id': product.id,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart!')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Buy Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Direct purchase flow
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
