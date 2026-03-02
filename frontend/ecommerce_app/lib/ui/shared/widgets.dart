import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/core/theme/app_theme.dart';

/// Reusable product card widget used across all UI layouts.
/// Adapts its styling based on the current user type.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final String userType;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showQuickAdd;
  final bool compactMode;

  const ProductCard({
    super.key,
    required this.product,
    this.userType = 'exploration',
    this.onTap,
    this.onAddToCart,
    this.showQuickAdd = false,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppTheme.getAccentColor(userType);
    final isPremiumUI = userType == 'premium';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isPremiumUI ? 6 : 2,
        color: isPremiumUI ? AppTheme.premiumSurface : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isPremiumUI ? 16 : 12),
          side: isPremiumUI
              ? const BorderSide(color: AppTheme.premiumColor, width: 0.5)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            Stack(
              children: [
                Container(
                  height: compactMode ? 120 : 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: accentColor,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                // Discount badge
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: userType == 'offer' ? Colors.red : accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.formattedDiscount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Premium badge
                if (product.isPremium && isPremiumUI)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.premiumColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'EXCLUSIVE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                // Quick add to cart button
                if (showQuickAdd)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            // Product info
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compactMode ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: isPremiumUI ? Colors.white : Colors.black87,
                      letterSpacing: isPremiumUI ? 0.5 : 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  if (product.avgRating > 0)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text(
                          '${product.avgRating}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isPremiumUI ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPremiumUI ? Colors.white54 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  // Price
                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: compactMode ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: isPremiumUI ? AppTheme.premiumColor : accentColor,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          product.formattedOriginalPrice,
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: isPremiumUI ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ],
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
}

/// Section header widget used across layouts.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onViewAll,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text('View All', style: TextStyle(color: color)),
            ),
        ],
      ),
    );
  }
}

/// Loading shimmer placeholder.
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Container(
            height: 160,
            color: Colors.grey[300],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Container(height: 14, width: 80, color: Colors.grey[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
