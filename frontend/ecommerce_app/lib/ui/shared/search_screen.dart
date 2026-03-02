import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app/providers/auth_provider.dart';
import 'package:ecommerce_app/models/product_model.dart';

/// Search screen with debounced text search, filters, and results grid.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<ProductModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filters
  double? _minPrice;
  double? _maxPrice;
  int? _categoryId;
  bool _onSaleOnly = false;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
      _doSearch(widget.initialQuery!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        _doSearch(query.trim());
      }
    });
  }

  Future<void> _doSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getProducts(
        search: query,
        page: 1,
        pageSize: 40,
        categoryId: _categoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        isOnSale: _onSaleOnly ? true : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      final products = (data['products'] as List)
          .map((p) => ProductModel.fromJson(p))
          .toList();
      setState(() {
        _results = products;
        _isLoading = false;
      });
      // Track search behavior
      api.trackSearch(query, products.length);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onSaleOnly: _onSaleOnly,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        onApply: (min, max, onSale, sort, order) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
            _onSaleOnly = onSale;
            _sortBy = sort;
            _sortOrder = order;
          });
          if (_searchCtrl.text.trim().length >= 2) {
            _doSearch(_searchCtrl.text.trim());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final crossAxisCount =
        isWide ? (MediaQuery.of(context).size.width ~/ 250) : 2;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onSubmitted: (q) {
            if (q.trim().length >= 2) _doSearch(q.trim());
          },
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _buildBody(crossAxisCount),
    );
  }

  Widget _buildBody(int crossAxisCount) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Search for products',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No results found',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Try different keywords or filters',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('${_results.length} results',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final product = _results[index];
              return _SearchProductCard(product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final ProductModel product;
  const _SearchProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final bool onSaleOnly;
  final String sortBy;
  final String sortOrder;
  final void Function(
      double? min, double? max, bool onSale, String sortBy, String sortOrder)
      onApply;

  const _FilterSheet({
    this.minPrice,
    this.maxPrice,
    required this.onSaleOnly,
    required this.sortBy,
    required this.sortOrder,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;
  late bool _onSale;
  late String _sort;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.minPrice?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(
        text: widget.maxPrice?.toStringAsFixed(0) ?? '');
    _onSale = widget.onSaleOnly;
    _sort = '${widget.sortBy}:${widget.sortOrder}';
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Price range
          const Text('Price Range',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min ₹',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max ₹',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // On sale toggle
          SwitchListTile(
            title: const Text('On Sale Only'),
            value: _onSale,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _onSale = v),
          ),
          const SizedBox(height: 8),
          // Sort
          const Text('Sort By',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sort,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(
                  value: 'created_at:desc', child: Text('Newest First')),
              DropdownMenuItem(
                  value: 'price:asc', child: Text('Price: Low to High')),
              DropdownMenuItem(
                  value: 'price:desc', child: Text('Price: High to Low')),
              DropdownMenuItem(
                  value: 'avg_rating:desc', child: Text('Top Rated')),
              DropdownMenuItem(
                  value: 'discount_percentage:desc',
                  child: Text('Best Discount')),
            ],
            onChanged: (v) => setState(() => _sort = v!),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, false, 'created_at', 'desc');
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final parts = _sort.split(':');
                    widget.onApply(
                      double.tryParse(_minCtrl.text),
                      double.tryParse(_maxCtrl.text),
                      _onSale,
                      parts[0],
                      parts[1],
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
