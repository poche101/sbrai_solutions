// lib/vendor/screen/category_products_screen.dart
import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen>
    with TranslationMixin<CategoryProductsScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  final Set<int> _favoriteIds = {};

  static const Color _orange = Color(0xFFE85D22);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _productService.getProducts(
        categoryId: widget.categoryId,
        perPage: 50,
        search: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );

      if (result['success'] == true) {
        final pagination = result['data'] as Map<String, dynamic>;
        final raw = pagination['data'] as List;

        setState(() {
          _products = raw
              .map((j) => Product.fromJson(j as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

        invalidateTranslation();
        _performTranslation();
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Category products error: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performTranslation() async {
    await translateIfNeeded(
      items: _products,
      onTranslate: (targetLang) async {
        setState(() => isTranslating = true);
        final futures = <Future<void>>[];

        for (final p in _products) {
          final key = p.id?.toString() ?? p.name;
          futures.add(
            translateText(p.name, targetLang).then((t) {
              if (t != null && mounted)
                setState(() => translatedNames[key] = t);
            }),
          );
          if (p.location.isNotEmpty) {
            futures.add(
              translateText(p.location, targetLang).then((t) {
                if (t != null && mounted)
                  setState(() => translatedLocations[key] = t);
              }),
            );
          }
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  void _toggleFavorite(Product product) {
    if (product.id == null) return;
    setState(() {
      if (_favoriteIds.contains(product.id)) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id!);
      }
    });

    _productService.toggleFavorite(product.id!).catchError((e) {
      setState(() {
        if (_favoriteIds.contains(product.id)) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id!);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: Text(widget.categoryName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: _orange,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _orange))
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : _products.isEmpty
            ? Center(
                child: Text(
                  l10n.noItemsFound ?? 'No products found',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final key = product.id?.toString() ?? product.name;
                  final name = translatedNames[key] ?? product.name;
                  final loc = translatedLocations[key] ?? product.location;
                  final isFavorited = _favoriteIds.contains(product.id);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrls.isNotEmpty
                                ? product.imageUrls.first
                                : '',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              loc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₦${product.price}",
                              style: TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleFavorite(product),
                              child: Icon(
                                isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorited ? Colors.red : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
