import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/vendor/vendor_menu.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';

// ── Category image map ─────────────────────────────────────────────────────────
const Map<String, String> _categoryImages = {
  'sharp-sand': 'assets/images/sharp_sand.jpg',
  'granite': 'assets/images/granite.jpg',
  'blocks': 'assets/images/blocks.jpg',
  'cement': 'assets/images/cement.jpg',
  'iron-rods': 'assets/images/rods.jpg',
  'paints': 'assets/images/paints.jpg',
  'furniture': 'assets/images/furniture.jpg',
  'scaffolding': 'assets/images/scaffolding.jpg',
  'logistics': 'assets/images/logistics.jpg',
  'borehole': 'assets/images/borehole.jpg',
  'cleaning': 'assets/images/cleaning.jpg',
  'fumigation': 'assets/images/fumigation.jpg',
  'apartments': 'assets/images/apartments.jpg',
  'houses': 'assets/images/houses.jpg',
  'commercial': 'assets/images/commercial.jpg',
  'land': 'assets/images/land.jpg',
};

const List<Map<String, String>> _supportedLocales = [
  {'code': 'en', 'label': 'EN', 'full': 'English'},
  {'code': 'fr', 'label': 'FR', 'full': 'Français'},
  {'code': 'ha', 'label': 'HA', 'full': 'Hausa'},
  {'code': 'yo', 'label': 'YO', 'full': 'Yorùbá'},
  {'code': 'ig', 'label': 'IG', 'full': 'Igbo'},
];

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> with TranslationMixin<VendorHomeScreen> {
  final ProductService _productService = ProductService();
  String selectedState = "All Nigeria";
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  List<Product> displayedProducts = [];
  bool isLoading = true;
  final Set<int> _favoriteProductIds = {};
  List<Map<String, dynamic>> categories = [];
  Map<String, int> _categoryNameToId = {};
  static const String _baseUrl = 'https://sbraisolutions.com/api/v1';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  Future<void> _performTranslation() async {
    await translateIfNeeded(
      items: displayedProducts,
      onTranslate: (targetLang) async {
        setState(() => isTranslating = true);
        final futures = <Future<void>>[];
        
        // Translate Products
        for (final product in displayedProducts) {
          final key = product.id?.toString() ?? product.name;
          futures.add(translateText(product.name, targetLang).then((t) {
            if (t != null && mounted) setState(() => translatedNames[key] = t);
          }));
          if (product.location.isNotEmpty) {
            futures.add(translateText(product.location, targetLang).then((t) {
              if (t != null && mounted) setState(() => translatedLocations[key] = t);
            }));
          }
        }

        // Translate Categories
        for (final cat in categories) {
          final name = cat['name'].toString();
          futures.add(translateText(name, targetLang).then((t) {
            if (t != null && mounted) setState(() => translatedDescriptions[name] = t);
          }));
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await _loadCategories();
      await _loadProducts();
    } finally {
      if (mounted) setState(() => isLoading = false);
      invalidateTranslation();
      _performTranslation();
    }
  }

  // ... (Rest of the loading methods remain same as provided)
  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          final grouped = data['data'] as Map<String, dynamic>;
          final List<Map<String, dynamic>> loaded = [];
          grouped.forEach((type, list) {
            if (list is List) {
              for (final cat in list) {
                loaded.add({'id': cat['id'], 'name': cat['name'], 'type': type, 'slug': cat['slug']});
                _categoryNameToId[cat['name']] = cat['id'];
              }
            }
          });
          categories = loaded;
        }
      }
    } catch (e) { debugPrint("❌ categories: $e"); }
  }

  Future<void> _loadProducts({int? categoryId}) async {
    try {
      final queryParams = {'page': '1', 'per_page': '40'};
      if (_searchController.text.isNotEmpty) queryParams['search'] = _searchController.text;
      if (selectedState != "All Nigeria") queryParams['search'] = "${queryParams['search'] ?? ''} $selectedState".trim();
      
      final uri = Uri.parse('$_baseUrl/ads').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final ads = (decoded['data'] is Map) ? decoded['data']['data'] : decoded['data'];
        displayedProducts = (ads as List).map((j) => Product.fromJson(j)).toList();
      }
    } catch (e) { debugPrint("❌ products: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: VendorMenu(userName: l10n.guestUser, userEmail: l10n.guestEmail),
      appBar: _buildAppBar(l10n),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFE85D22),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    Text(l10n.appTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSearchBar(l10n),
                    const SizedBox(height: 20),
                    _buildCategoryGrid(l10n),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.recommendedForYou, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isTranslating) const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
            if (isLoading) const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
            else SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, mainAxisSpacing: 12, crossAxisSpacing: 12),
                delegate: SliverChildBuilderDelegate((ctx, i) => _buildProductCard(displayedProducts[i], l10n), childCount: displayedProducts.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers utilizing translatedNames and translatedLocations ---

  Widget _buildCategoryGrid(AppLocalizations l10n) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.78),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final originalName = categories[i]['name'].toString();
        // We reuse translatedDescriptions map for category names to keep mixin simple
        final displayName = translatedDescriptions[originalName] ?? originalName;
        return Column(
          children: [
            const Icon(Icons.category, color: Colors.white),
            Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product, AppLocalizations l10n) {
    final key = product.id?.toString() ?? product.name;
    final name = translatedNames[key] ?? product.name;
    final loc = translatedLocations[key] ?? product.location;
    return Card(
      child: Column(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(loc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text("₦${product.price}"),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: const Text("SBRAI Solutions"),
      actions: [
        PopupMenuButton<String>(
          onSelected: (code) => context.read<LanguageProvider>().setLanguage(Locale(code)),
          itemBuilder: (_) => _supportedLocales.map((l) => PopupMenuItem(value: l['code'], child: Text(l['full']!))).toList(),
          child: const Icon(Icons.language),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(hintText: l10n.iAmLookingFor, fillColor: Colors.white, filled: true),
      onSubmitted: (_) => _loadAll(),
    );
  }
}
