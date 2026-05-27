import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/buyer/widgets/buyers_menu.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TranslationMixin<HomeScreen> {
  final ApiService _apiService = ApiService();
  final ProductService _productService = ProductService();
  late final ChatService _chatService;
  
  String userName = "";
  String userEmail = "";
  int currentUserId = 0;
  String authToken = "";

  String selectedState = "All Nigeria";
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Product> displayedProducts = [];
  bool isLoading = true;
  String? errorMessage;

  final Set<int> _favoriteProductIds = {};
  Map<String, int> _categoryNameToId = {};

  final List<String> nigeriaStates = [
    "All Nigeria", "Abia", "Adamawa", "Akwa Ibom", "Anambra", "Bauchi", "Bayelsa",
    "Benue", "Borno", "Cross River", "Delta", "Ebonyi", "Edo", "Ekiti", "Enugu",
    "FCT", "Gombe", "Imo", "Jigawa", "Kaduna", "Kano", "Katsina", "Kebbi", "Kogi",
    "Kwara", "Lagos", "Nasarawa", "Niger", "Ogun", "Ondo", "Osun", "Oyo", "Plateau",
    "Rivers", "Sokoto", "Taraba", "Yobe", "Zamfara",
  ];

  final List<Map<String, String>> categories = [
    {'name': 'Sharp Sand', 'icon': 'assets/images/sharp_sand.jpg'},
    {'name': 'Granite', 'icon': 'assets/images/granite.jpg'},
    {'name': 'Blocks', 'icon': 'assets/images/blocks.jpg'},
    {'name': 'Cement', 'icon': 'assets/images/cement.jpg'},
    {'name': 'Iron Rods', 'icon': 'assets/images/rods.jpg'},
    {'name': 'Paints', 'icon': 'assets/images/paints.jpg'},
    {'name': 'Furniture', 'icon': 'assets/images/furniture.jpg'},
    {'name': 'Scaffolding', 'icon': 'assets/images/scaffolding.jpg'},
    {'name': 'Logistics', 'icon': 'assets/images/logistics.jpg'},
    {'name': 'Borehole', 'icon': 'assets/images/borehole.jpg'},
    {'name': 'Cleaning', 'icon': 'assets/images/cleaning.jpg'},
    {'name': 'Fumigation', 'icon': 'assets/images/fumigation.jpg'},
    {'name': 'Apartments', 'icon': 'assets/images/apartments.jpg'},
    {'name': 'Houses', 'icon': 'assets/images/houses.jpg'},
    {'name': 'Commercial', 'icon': 'assets/images/commercial.jpg'},
    {'name': 'Land', 'icon': 'assets/images/land.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCategories();
    _fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          final name = cat['name']!;
          futures.add(translateText(name, targetLang).then((t) {
            if (t != null && mounted) setState(() => translatedDescriptions[name] = t);
          }));
        }

        await Future.wait(futures);
        if (mounted) setState(() => isTranslating = false);
      },
    );
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _apiService.getUserData();
      setState(() {
        userName = userData['name']?.toString() ?? "Buyer";
        userEmail = userData['email']?.toString() ?? "";
        currentUserId = (userData['id'] as int?) ?? (int.tryParse(userData['id']?.toString() ?? '') ?? 0);
        authToken = userData['token']?.toString() ?? (userData['access_token']?.toString() ?? "");
        _chatService = ChatService(authToken);
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://sbraisolutions.com/api/v1/categories'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map) {
          final allCats = data['data'] as Map<String, dynamic>;
          final map = <String, int>{};
          allCats.forEach((type, list) {
            for (final cat in list) {
              map[cat['name']] = cat['id'];
            }
          });
          setState(() => _categoryNameToId = map);
        }
      }
    } catch (e) {
      debugPrint('Category fetch error: $e');
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? search;
      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty || selectedState != "All Nigeria") {
        search = "${searchText} ${selectedState != "All Nigeria" ? selectedState : ""}".trim();
      }

      int? categoryId = (selectedCategory != null) ? _categoryNameToId[selectedCategory] : null;

      final response = await _productService.getProducts(
        page: 1,
        perPage: 40,
        search: search,
        categoryId: categoryId,
      );

      final dynamic responseData = response['data'];
      List<dynamic> adsList = (responseData is Map && responseData.containsKey('data'))
          ? (responseData['data'] as List<dynamic>?) ?? []
          : (responseData is List) ? responseData : [];

      setState(() {
        displayedProducts = adsList.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
        isLoading = false;
      });
      
      invalidateTranslation();
      _performTranslation();
    } catch (e) {
      debugPrint("❌ Error loading ads: $e");
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterByCategory(String categoryName) {
    setState(() {
      selectedCategory = (selectedCategory == categoryName) ? null : categoryName;
    });
    _fetchProducts();
  }

  Future<void> _toggleFavorite(Product product) async {
    if (product.id == null) return;
    setState(() {
      if (_favoriteProductIds.contains(product.id)) {
        _favoriteProductIds.remove(product.id);
      } else {
        _favoriteProductIds.add(product.id!);
      }
    });

    try {
      await _apiService.toggleFavorite(product.id!);
    } catch (e) {
      setState(() {
        if (_favoriteProductIds.contains(product.id)) {
          _favoriteProductIds.remove(product.id);
        } else {
          _favoriteProductIds.add(product.id!);
        }
      });
    }
  }

  void _openChat(Product product) {
    if (currentUserId == 0 || authToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to start chat")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: product.chatId ?? 0,
          authToken: authToken,
          currentUserId: currentUserId,
          otherPartyName: "Seller",
          otherPartyInitial: 'S',
          adTitle: product.name,
          otherPartyId: product.vendorId ?? 0,
          service: _chatService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: BuyersMenu(userName: userName, userEmail: userEmail),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset('assets/images/logo.png', height: 25),
        actions: [
          _buildLanguageDropdown(context),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline, color: Colors.black87),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                userName.isNotEmpty ? userName.split(' ')[0] : "User",
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        color: const Color(0xFFE85D22),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFE85D22),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Column(
                  children: [
                    Text(l10n.appTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildFunctionalSearchBar(l10n),
                    const SizedBox(height: 25),
                    _buildDynamicCategoryGrid(l10n),
                    const SizedBox(height: 15),
                    _buildTrendingSection(l10n),
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
                    Text(
                      selectedCategory == null ? l10n.recommendedForYou : "${l10n.resultsFor} ${translatedDescriptions[selectedCategory] ?? selectedCategory}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isTranslating) const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
            if (isLoading) const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 50.0), child: CircularProgressIndicator(color: Color(0xFFE85D22)))))
            else if (displayedProducts.isEmpty) SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.only(top: 50.0), child: Text(l10n.noItemsFound))))
            else SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, mainAxisSpacing: 12, crossAxisSpacing: 12),
                delegate: SliverChildBuilderDelegate((context, index) => _buildDynamicProductCard(displayedProducts[index], l10n), childCount: displayedProducts.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicProductCard(Product product, AppLocalizations l10n) {
    final key = product.id?.toString() ?? product.name;
    final name = translatedNames[key] ?? product.name;
    final loc = translatedLocations[key] ?? product.location;
    final bool isFavorited = _favoriteProductIds.contains(product.id);
    final bool isService = ['logistics', 'borehole', 'cleaning', 'fumigation'].contains(product.category.toLowerCase());

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: product, userName: userName))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(product.imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey))),
                  ),
                  if (isService) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)), child: Text(l10n.service, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                  Positioned(top: 8, right: 8, child: GestureDetector(onTap: () => _toggleFavorite(product), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle), child: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, size: 18, color: isFavorited ? Colors.red : Colors.grey)))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.location_on, size: 12, color: Colors.grey), const SizedBox(width: 2), Expanded(child: Text(loc, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 8),
                  Text("₦${product.price.toStringAsFixed(0)}", style: const TextStyle(color: Color(0xFFE85D22), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSmallButton(l10n.call, Icons.call_outlined, false)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSmallButton(l10n.chat, Icons.chat_bubble_outline, true, onTap: () => _openChat(product))),
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

  Widget _buildSmallButton(String label, IconData icon, bool isPrimary, {VoidCallback? onTap}) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(backgroundColor: isPrimary ? const Color(0xFFE85D22) : Colors.transparent, side: BorderSide(color: isPrimary ? const Color(0xFFE85D22) : Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
        onPressed: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 14, color: isPrimary ? Colors.white : Colors.black87), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: isPrimary ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildDynamicCategoryGrid(AppLocalizations l10n) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 18, crossAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final originalName = categories[index]['name']!;
        final displayName = translatedDescriptions[originalName] ?? originalName;
        final isSelected = selectedCategory == originalName;
        return GestureDetector(
          onTap: () => _filterByCategory(originalName),
          child: Column(
            children: [
              Expanded(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: isSelected ? Border.all(color: Colors.white, width: 2) : null, image: DecorationImage(image: AssetImage(categories[index]['icon']!), fit: BoxFit.cover)))),
              const SizedBox(height: 6),
              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunctionalSearchBar(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PopupMenuButton<String>(
            onSelected: (value) { setState(() => selectedState = value); _fetchProducts(); },
            itemBuilder: (context) => nigeriaStates.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(selectedState, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)), const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18)])),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 7,
          child: Container(
            height: 48,
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _searchController, onSubmitted: (_) => _fetchProducts(), style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: l10n.iAmLookingFor, hintStyle: const TextStyle(color: Colors.white54, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 15)))),
                IconButton(onPressed: _fetchProducts, icon: const Icon(Icons.search, color: Colors.white, size: 22), style: IconButton.styleFrom(backgroundColor: const Color(0xFFE85D22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale.languageCode;
    final List<Map<String, String>> supportedLocales = [
      {'code': 'en', 'label': 'EN', 'full': 'English'},
      {'code': 'fr', 'label': 'FR', 'full': 'Français'},
      {'code': 'ha', 'label': 'HA', 'full': 'Hausa'},
      {'code': 'yo', 'label': 'YO', 'full': 'Yorùbá'},
      {'code': 'ig', 'label': 'IG', 'full': 'Igbo'},
    ];

    return PopupMenuButton<String>(
      initialValue: currentLocale,
      onSelected: (code) => languageProvider.setLanguage(Locale(code)),
      itemBuilder: (context) => supportedLocales.map((l) => PopupMenuItem<String>(value: l['code'], child: Text(l['full']!))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: Row(children: [Text(supportedLocales.firstWhere((l) => l['code'] == currentLocale)['label']!, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)), const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 14)]),
      ),
    );
  }

  Widget _buildTrendingSection(AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.trending, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(onPressed: () {}, icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20)),
      ],
    );
  }
}
