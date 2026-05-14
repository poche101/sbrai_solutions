import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/vendor/vendor_menu.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';

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

// ── Supported locales ─────────────────────────────────────────────────────────
const List<Map<String, String>> _supportedLocales = [
  {'code': 'en', 'label': 'EN', 'full': 'English'},
  {'code': 'fr', 'label': 'FR', 'full': 'Français'},
  {'code': 'ha', 'label': 'HA', 'full': 'Hausa'},
  {'code': 'yo', 'label': 'YO', 'full': 'Yorùbá'},
  {'code': 'ig', 'label': 'IG', 'full': 'Igbo'},
];

// ══════════════════════════════════════════════════════════════════════════════
// HomeScreen
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();

  String selectedState = "All Nigeria";
  String? selectedCategory;
  String _currentLocale = 'en';

  final TextEditingController _searchController = TextEditingController();

  List<Product> displayedProducts = [];
  bool isLoading = true;

  final Set<int> _favoriteProductIds = {};

  List<Map<String, dynamic>> categories = [];
  Map<String, int> _categoryNameToId = {};

  static const String _baseUrl = 'https://sbraisolutions.com/api/v1';

  final List<String> nigeriaStates = [
    "All Nigeria",
    "Abia",
    "Adamawa",
    "Akwa Ibom",
    "Anambra",
    "Bauchi",
    "Bayelsa",
    "Benue",
    "Borno",
    "Cross River",
    "Delta",
    "Ebonyi",
    "Edo",
    "Ekiti",
    "Enugu",
    "FCT",
    "Gombe",
    "Imo",
    "Jigawa",
    "Kaduna",
    "Kano",
    "Katsina",
    "Kebbi",
    "Kogi",
    "Kwara",
    "Lagos",
    "Nasarawa",
    "Niger",
    "Ogun",
    "Ondo",
    "Osun",
    "Oyo",
    "Plateau",
    "Rivers",
    "Sokoto",
    "Taraba",
    "Yobe",
    "Zamfara",
  ];

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

  // ── Loaders ──────────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await _loadCategories();
      await _loadProducts();
    } catch (e) {
      debugPrint("❌ _loadAll error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/categories'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          final grouped = data['data'] as Map<String, dynamic>;
          final List<Map<String, dynamic>> loaded = [];
          final Map<String, int> nameToId = {};

          grouped.forEach((type, list) {
            if (list is List) {
              for (final cat in list) {
                final name = cat['name']?.toString() ?? '';
                final id = cat['id'] as int?;
                final slug = cat['slug']?.toString() ?? '';
                if (name.isNotEmpty && id != null) {
                  loaded.add({
                    'id': id,
                    'name': name,
                    'type': type,
                    'slug': slug,
                  });
                  nameToId[name] = id;
                }
              }
            }
          });

          categories = loaded;
          _categoryNameToId = nameToId;
        }
      }
    } catch (e) {
      debugPrint("❌ _loadCategories: $e");
    }
  }

  Future<void> _loadProducts({int? categoryId}) async {
    try {
      final queryParams = <String, String>{'page': '1', 'per_page': '40'};

      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty && selectedState != "All Nigeria") {
        queryParams['search'] = '$searchText $selectedState';
      } else if (searchText.isNotEmpty) {
        queryParams['search'] = searchText;
      } else if (selectedState != "All Nigeria") {
        queryParams['search'] = selectedState;
      }

      final cid =
          categoryId ??
          (selectedCategory != null &&
                  _categoryNameToId.containsKey(selectedCategory)
              ? _categoryNameToId[selectedCategory]
              : null);
      if (cid != null) queryParams['category_id'] = cid.toString();

      final uri = Uri.parse(
        '$_baseUrl/ads',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = decoded['data'];
        List<dynamic> adsList =
            responseData is Map && responseData.containsKey('data')
            ? (responseData['data'] as List<dynamic>?) ?? []
            : responseData is List
            ? responseData
            : [];

        displayedProducts = adsList
            .map((j) => Product.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("❌ _loadProducts: $e");
    }
  }

  Future<void> _onRefresh() => _loadAll();

  // ── Category tap → open category page ────────────────────────────────────────

  void _openCategoryPage(Map<String, dynamic> cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryProductsPage(
          categoryId: cat['id'] as int,
          categoryName: cat['name'].toString(),
          categorySlug: cat['slug']?.toString() ?? '',
          baseUrl: _baseUrl,
        ),
      ),
    );
  }

  void _toggleFavorite(Product product) {
    if (product.id == null) return;
    setState(() {
      if (_favoriteProductIds.contains(product.id)) {
        _favoriteProductIds.remove(product.id);
      } else {
        _favoriteProductIds.add(product.id!);
      }
    });
  }

  Future<void> _openChat(Product product) async {
    final apiService = ApiService();
    final token = await apiService.getToken() ?? '';
    final userData = await apiService.getUserData();
    final currentUserId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: product.chatId ?? 0,
          authToken: token,
          currentUserId: currentUserId,
          otherPartyName: product.vendorName ?? 'Seller',
          otherPartyInitial: (product.vendorName?.isNotEmpty ?? false)
              ? product.vendorName![0].toUpperCase()
              : 'S',
          adTitle: product.name,
          otherPartyId: product.vendorId ?? 0,
          service: ChatService(token),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const VendorMenu(
        userName: "Guest User",
        userEmail: "guest@example.com",
      ),
      appBar: _buildAppBar(l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostAdScreen()),
        ).then((_) => _loadAll()),
        backgroundColor: const Color(0xFFE85D22),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFFE85D22),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Orange header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFE85D22),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(l10n),
                    const SizedBox(height: 20),
                    _buildCategoryGrid(),
                  ],
                ),
              ),
            ),

            // ── Section header ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
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
                    Text(
                      "${displayedProducts.length} ${l10n.items}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Products / Loading / Empty ─────────────────────────────────
            if (isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFFE85D22)),
                  ),
                ),
              )
            else if (displayedProducts.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noItemsFound,
                          style: TextStyle(color: Colors.grey.shade500),
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
                    childAspectRatio: 0.62,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildProductCard(displayedProducts[i], l10n),
                    childCount: displayedProducts.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Image.asset('assets/images/logo.png', height: 28),
      actions: [
        _buildLanguageDropdown(),
        const SizedBox(width: 16),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, color: Colors.black87, size: 20),
            SizedBox(width: 4),
            Text(
              "Vendor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 12),
          ],
        ),
      ],
    );
  }

  // ── Language dropdown ────────────────────────────────────────────────────────

  Widget _buildLanguageDropdown() {
    return PopupMenuButton<String>(
      initialValue: _currentLocale,
      onSelected: (code) => setState(() => _currentLocale = code),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => _supportedLocales
          .map(
            (l) => PopupMenuItem<String>(
              value: l['code'],
              child: Text(
                l['full']!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _supportedLocales.firstWhere(
                (l) => l['code'] == _currentLocale,
                orElse: () => _supportedLocales.first,
              )['label']!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Row(
      children: [
        // State picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E237E),
            borderRadius: BorderRadius.circular(10),
          ),
          height: 48,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedState,
              dropdownColor: const Color(0xFF1E237E),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
              items: nigeriaStates
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => selectedState = v);
                  _loadAll();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Search field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'I am looking for...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onSubmitted: (_) => _loadAll(),
                  ),
                ),
                GestureDetector(
                  onTap: _loadAll,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE85D22),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 22,
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

  // ── Category grid ────────────────────────────────────────────────────────────

  Widget _buildCategoryGrid() {
    if (isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          "No categories available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final name = cat['name'].toString();
        final slug = cat['slug']?.toString() ?? '';
        final imgPath = _categoryImages[slug];

        return GestureDetector(
          onTap: () => _openCategoryPage(cat),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imgPath != null
                      ? Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _categoryPlaceholder(),
                        )
                      : _categoryPlaceholder(),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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

  Widget _categoryPlaceholder() => Container(
    color: Colors.white24,
    child: const Icon(Icons.category_outlined, color: Colors.white54, size: 28),
  );

  // ── Product card ─────────────────────────────────────────────────────────────

  Widget _buildProductCard(Product product, AppLocalizations l10n) {
    final bool isFav = _favoriteProductIds.contains(product.id);
    final bool isService = [
      'logistics',
      'borehole',
      'cleaning',
      'fumigation',
    ].contains(product.category.toLowerCase());

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: product,
            userName: product.userName,
          ),
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.imageUrl.startsWith('http')
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Image.asset(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                  if (isService)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.service,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFav ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                          product.location,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₦${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Color(0xFFE85D22),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          l10n.call,
                          Icons.call_outlined,
                          false,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionBtn(
                          l10n.chat,
                          Icons.chat_bubble_outline,
                          true,
                          onTap: () => _openChat(product),
                        ),
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

  Widget _actionBtn(
    String label,
    IconData icon,
    bool primary, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFFE85D22)
              : Colors.transparent,
          side: BorderSide(
            color: primary ? const Color(0xFFE85D22) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: primary ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: primary ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category Products Page
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categorySlug;
  final String baseUrl;

  const _CategoryProductsPage({
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.baseUrl,
  });

  @override
  State<_CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<_CategoryProductsPage> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/ads').replace(
        queryParameters: {
          'page': '1',
          'per_page': '40',
          'category_id': widget.categoryId.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = decoded['data'];
        List<dynamic> adsList =
            responseData is Map && responseData.containsKey('data')
            ? (responseData['data'] as List?) ?? []
            : responseData is List
            ? responseData
            : [];

        if (mounted) {
          setState(
            () => products = adsList
                .map((j) => Product.fromJson(j as Map<String, dynamic>))
                .toList(),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ category page error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = _categoryImages[widget.categorySlug];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar with category image ────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFE85D22),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: imgPath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(imgPath, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(color: const Color(0xFFE85D22)),
            ),
          ),

          // ── Count header ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${products.length} items",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // ── Products ──────────────────────────────────────────────────────
          if (isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: CircularProgressIndicator(color: Color(0xFFE85D22)),
                ),
              ),
            )
          else if (products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No products in ${widget.categoryName} yet",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildProductListCard(products[i]),
                  childCount: products.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProductListCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            product: product,
            userName: product.userName,
          ),
        ),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 85,
                  height: 85,
                  child: product.imageUrl.startsWith('http')
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Image.asset(product.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.location,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₦${product.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Color(0xFFE85D22),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
