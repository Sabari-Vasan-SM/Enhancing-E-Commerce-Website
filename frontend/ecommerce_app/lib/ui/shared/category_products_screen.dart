import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/models/product_model.dart';

/// Category products screen - shows all products in a category with pagination.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _page = 1;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getProducts(
        categoryId: widget.categoryId,
        page: 1,
        pageSize: 20,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      setState(() {
        _products = (data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList();
        _hasMore = data['has_next'] ?? false;
        _page = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getProducts(
        categoryId: widget.categoryId,
        page: _page + 1,
        pageSize: 20,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      setState(() {
        _products.addAll((data['products'] as List)
            .map((p) => ProductModel.fromJson(p))
            .toList());
        _hasMore = data['has_next'] ?? false;
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final crossAxisCount =
        isWide ? (MediaQuery.of(context).size.width ~/ 250) : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) {
              final parts = val.split(':');
              _sortBy = parts[0];
              _sortOrder = parts[1];
              _loadProducts();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'created_at:desc', child: Text('Newest First')),
              const PopupMenuItem(
                  value: 'price:asc', child: Text('Price: Low to High')),
              const PopupMenuItem(
                  value: 'price:desc', child: Text('Price: High to Low')),
              const PopupMenuItem(
                  value: 'avg_rating:desc', child: Text('Top Rated')),
              const PopupMenuItem(
                  value: 'discount_percentage:desc',
                  child: Text('Best Discount')),
            ],
          ),
        ],
      ),
      body: _products.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No products found'))
              : RefreshIndicator(
                  onRefresh: () async => _loadProducts(),
                  child: GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _products.length) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      return _ProductCard(product: _products[index]);
                    },
                  ),
                ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image,
                            size: 40, color: Colors.grey)),
                    errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            size: 40, color: Colors.grey)),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(product.formattedDiscount,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${product.avgRating}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('(${product.reviewCount})',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ]),
                    const SizedBox(height: 4),
                    Text(product.formattedPrice,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary)),
                    if (product.hasDiscount)
                      Text(product.formattedOriginalPrice,
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12)),
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
