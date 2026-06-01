// lib/vendor/screens/vendor_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/services/vendor/vendor_auth_service.dart';
import 'package:sbrai_solutions/vendor/vendor_menu.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/vendor/screen/category_products_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';
import 'package:sbrai_solutions/screens/chat_screen.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

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

const List<String> _nigeriaStates = [
  'All Nigeria',
  'Abia',
  'Adamawa',
  'Akwa Ibom',
  'Anambra',
  'Bauchi',
  'Bayelsa',
  'Benue',
  'Borno',
  'Cross River',
  'Delta',
  'Ebonyi',
  'Edo',
  'Ekiti',
  'Enugu',
  'FCT',
  'Gombe',
  'Imo',
  'Jigawa',
  'Kaduna',
  'Kano',
  'Katsina',
  'Kebbi',
  'Kogi',
  'Kwara',
  'Lagos',
  'Nasarawa',
  'Niger',
  'Ogun',
  'Ondo',
  'Osun',
  'Oyo',
  'Plateau',
  'Rivers',
  'Sokoto',
  'Taraba',
  'Yobe',
  'Zamfara',
];

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen>
    with TranslationMixin<VendorHomeScreen> {
  final ProductService _productService = ProductService();
  final VendorAuthService _authService = VendorAuthService();

  String _selectedState = 'All Nigeria';
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  final Set<int> _favoriteIds = {};

  String _vendorName = '';
  String _vendorEmail = '';
  int _vendorUserId = 0;

  String? _productError;

  static const Color _orange = Color(0xFFE85D22);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _productError = null;
    });
    try {
      await Future.wait([
        _loadVendorProfile(),
        _loadCategories(),
        _loadProducts(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        invalidateTranslation();
        _performTranslation();
      }
    }
  }

  Future<void> _loadVendorProfile() async {
    try {
      final profile = await _authService.getProfile();
      final data = profile['data'] as Map<String, dynamic>? ?? profile;
      if (mounted) {
        setState(() {
          _vendorName =
              data['full_name']?.toString() ?? data['name']?.toString() ?? '';
          _vendorEmail = data['email']?.toString() ?? '';
          _vendorUserId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint("❌ vendor profile: $e");
    }
  }

  Future<void> _loadCategories() async {
    try {
      final loaded = await _productService.getCategories();
      if (mounted) setState(() => _categories = loaded);
    } catch (e) {
      debugPrint("❌ categories error: $e");
    }
  }

  Future<void> _loadProducts() async {
    try {
      String? search = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;
      if (_selectedState != 'All Nigeria') {
        search = '${search ?? ''} $_selectedState'.trim();
      }

      final result = await _productService.getProducts(
        search: search,
        perPage: 40,
      );

      debugPrint('📦 getProducts result keys: ${result.keys.toList()}');
      debugPrint('📦 success: ${result['success']}');

      final isSuccess =
          result['success'] == true || result['success'].toString() == 'true';

      if (!isSuccess) {
        throw Exception(
          result['message']?.toString() ?? 'Failed to load products',
        );
      }

      final dynamic outer = result['data'];
      List<dynamic> raw = [];

      if (outer is Map<String, dynamic>) {
        final inner = outer['data'];
        if (inner is List) {
          raw = inner;
        }
      } else if (outer is List) {
        raw = outer;
      }

      debugPrint('📦 Parsed ${raw.length} products');

      if (mounted) {
        setState(() {
          _products = raw
              .map((j) => Product.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("❌ products error: $e");
      if (mounted) setState(() => _productError = e.toString());
    }
  }

  // ── Translation ────────────────────────────────────────────────────────────

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

        for (final cat in _categories) {
          final name = cat['name'].toString();
          futures.add(
            translateText(name, targetLang).then((t) {
              if (t != null && mounted)
                setState(() => translatedDescriptions[name] = t);
            }),
          );
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onCategoryTap(Map<String, dynamic> cat) {
    final displayName =
        translatedDescriptions[cat['name'].toString()] ??
        cat['name'].toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(
          categoryId: cat['id'] as int,
          categoryName: displayName,
        ),
      ),
    );
  }

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot call $phoneNumber')));
      }
    }
  }

  Future<void> _openChat(Product product) async {
    if (_vendorUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log out and log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int resolvedChatId = product.chatId ?? 0;

    if (resolvedChatId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening chat...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      try {
        final chatService = ChatService(currentUserId: _vendorUserId);
        final thread = await chatService.startChat(
          adId: product.id ?? 0,
          message: 'Hi, I am interested in this listing.',
        );
        resolvedChatId = thread.id;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
        }
        return;
      }
    }

    if (!mounted) return;

    final vendorName = (product.vendorName?.trim().isNotEmpty == true)
        ? product.vendorName!
        : 'Seller';
    final initial = vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'S';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: resolvedChatId,
          currentUserId: _vendorUserId,
          otherPartyName: vendorName,
          otherPartyInitial: initial,
          adTitle: product.name,
          otherPartyId: product.vendorId ?? 0,
          service: ChatService(currentUserId: _vendorUserId),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: VendorMenu(
        userName: _vendorName.isNotEmpty ? _vendorName : l10n.guestUser,
        userEmail: _vendorEmail.isNotEmpty ? _vendorEmail : l10n.guestEmail,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostAdScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 25,
          errorBuilder: (_, __, ___) => const Text(
            'Sbrai',
            style: TextStyle(
              color: Color(0xFFE85D22),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        actions: [
          _buildLanguageDropdown(context),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline, color: Colors.black87),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _vendorName.isNotEmpty
                    ? _vendorName.split(' ').first
                    : 'Vendor',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: _orange,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Orange hero ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: _orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      'What are you looking for?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFunctionalSearchBar(l10n),
                    const SizedBox(height: 25),
                    _buildCategoryGrid(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),

            // ── Recommended header ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recommendedForYou,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (isTranslating)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        Text(
                          '${_products.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Products ───────────────────────────────────────────────────
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(color: _orange),
                  ),
                ),
              )
            else if (_productError != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _productError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_products.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No listings found',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildProductCard(_products[i], l10n),
                    childCount: _products.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildFunctionalSearchBar(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedState = value);
              _loadProducts();
            },
            itemBuilder: (_) => _nigeriaStates
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedState,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadProducts(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.iAmLookingFor,
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78, // Reduced width slightly
      ),
      itemCount: _categories.length,
      itemBuilder: (_, i) {
        final cat = _categories[i];
        final originalName = cat['name'].toString();
        final displayName =
            translatedDescriptions[originalName] ?? originalName;
        final slug = cat['slug']?.toString() ?? '';
        final assetPath = _categoryImages[slug];

        return GestureDetector(
          onTap: () => _onCategoryTap(cat),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: assetPath != null
                      ? Image.asset(assetPath, fit: BoxFit.cover)
                      : const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product, AppLocalizations l10n) {
    final key = product.id?.toString() ?? product.name;
    final name = translatedNames[key] ?? product.name;
    final loc = translatedLocations[key] ?? product.location;
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : null;
    final isFavorited = _favoriteIds.contains(product.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: (imageUrl != null && !imageUrl.startsWith('assets/'))
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _orange,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 36,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorited ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 11,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          loc,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${_formatPrice(product.price)}',
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale.languageCode;

    return PopupMenuButton<String>(
      initialValue: currentLocale,
      onSelected: (code) => languageProvider.setLanguage(Locale(code)),
      itemBuilder: (_) => _supportedLocales
          .map(
            (l) => PopupMenuItem<String>(
              value: l['code'],
              child: Text(l['full']!),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              _supportedLocales.firstWhere(
                (l) => l['code'] == currentLocale,
                orElse: () => _supportedLocales.first,
              )['label']!,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _toggleFavorite(Product product) {
    if (product.id == null) return;
    setState(() {
      if (_favoriteIds.contains(product.id)) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id!);
      }
    });
    _productService.toggleFavorite(product.id!).catchError((_) {
      setState(() {
        if (_favoriteIds.contains(product.id)) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id!);
        }
      });
    });
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num p = price is num ? price : num.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return p.toStringAsFixed(0);
  }
}
