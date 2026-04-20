import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/buyer/product_model.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/vendor/vendor_menu.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';
<<<<<<< HEAD
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';
import 'package:sbrai_solutions/vendor/screen/product_details_screen.dart';
import 'package:sbrai_solutions/services/vendor/services.dart';
=======
import 'package:sbrai_solutions/providers/language_provider.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final ServiceProvider _serviceProvider = ServiceProvider();

  String selectedState = "All Nigeria";
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Product> displayedProducts = [];
  bool isLoading = true;

<<<<<<< HEAD
  final String userFullName = "Demo User";
=======
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
  final Set<int> _favoriteProductIds = {};

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
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final List<String> serviceCategoryNames = [
        'Logistics',
        'Borehole',
        'Cleaning',
        'Fumigation',
      ];

      if (selectedCategory != null &&
          serviceCategoryNames.contains(selectedCategory)) {
        final services = await _serviceProvider.getServices();

        setState(() {
          displayedProducts = services.map((s) {
            // Fix: Safe URL resolution using firstOrNull to avoid dead code warnings
            String resolvedImageUrl =
                s.photos.firstOrNull?.fullUrl ??
                "https://via.placeholder.com/150";

            return Product(
              id: s.id,
              name: s.title,
              price: s.price ?? 0.0,
              // Wrap the single URL in a list to match the new model requirement
              imageUrls: [resolvedImageUrl],
              location: s.location ?? "Nigeria",
              category: selectedCategory ?? "General",
              userName: "Service Provider",
              vendorName: "Professional Artisan",
              rating: 0.0,
            );
          }).toList();
          isLoading = false;
        });
      } else {
        final response = await _productService.getProducts(
          page: 1,
          perPage: 40,
          state: selectedState == "All Nigeria" ? null : selectedState,
          search: _searchController.text.isNotEmpty
              ? _searchController.text
              : null,
          category: selectedCategory,
        );

        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          displayedProducts = data
              .map((json) => Product.fromJson(json))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading products: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterByCategory(String categoryName) {
    setState(
      () => selectedCategory = (selectedCategory == categoryName)
          ? null
          : categoryName,
    );
    _fetchProducts();
  }

  void _toggleFavorite(Product product) {
    if (product.id == null) return;
<<<<<<< HEAD
=======

>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
    setState(() {
      if (_favoriteProductIds.contains(product.id)) {
        _favoriteProductIds.remove(product.id);
      } else {
        _favoriteProductIds.add(product.id!);
<<<<<<< HEAD
=======
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product.name} added to favorites"),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: "View",
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const VendorMenu(
        userName: "Guest User",
        userEmail: "guest@example.com",
      ),
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
          const Center(
            child: Text(
              "  Vendor      ",
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostAdScreen()),
        ),
        backgroundColor: const Color(0xFFE85D22),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.appTitle, // Using translation
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFunctionalSearchBar(),
                    const SizedBox(height: 25),
                    _buildDynamicCategoryGrid(),
                    const SizedBox(height: 15),
                    _buildTrendingSection(),
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
                      selectedCategory == null
                          ? "Recommended for You"
                          : "Results for $selectedCategory",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${displayedProducts.length} items",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85D22),
                        ),
                      ),
                    ),
                  )
                : displayedProducts.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Text("No items found."),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildDynamicProductCard(displayedProducts[index]),
                        childCount: displayedProducts.length,
                      ),
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicProductCard(Product product) {
    final bool isFavorited = _favoriteProductIds.contains(product.id);
    final List<String> serviceCategories = [
      'logistics',
      'borehole',
      'cleaning',
      'fumigation',
    ];
    final bool isService = serviceCategories.contains(
      product.category.toLowerCase(),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductDetailsScreen(product: product, userName: userFullName),
        ),
      ),
<<<<<<< HEAD
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
=======
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
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
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
                        boxShadow: [
                          const BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorited ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Fix: Use Positioned.fill to solve the squashed/tiny image issue
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  if (isService)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "Service",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
<<<<<<< HEAD
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(product),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withOpacity(0.9),
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
=======
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        "Call",
                        Icons.call_outlined,
                        false,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        "Chat",
                        Icons.chat_bubble_outline,
                        true,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ],
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₦${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}",
                    style: const TextStyle(
                      color: Color(0xFFE85D22),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          "Call",
                          Icons.call_outlined,
                          false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          "Chat",
                          Icons.chat_bubble_outline,
                          true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  product: product,
                                  userName: product.userName,
                                  userInitial: product.userName.isNotEmpty
                                      ? product.userName[0].toUpperCase()
                                      : 'U',
                                ),
                              ),
                            );
                          },
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    bool isPrimary, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFE85D22) : Colors.transparent,
          side: BorderSide(
            color: isPrimary ? const Color(0xFFE85D22) : Colors.grey.shade300,
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
              size: 14,
              color: isPrimary ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isPrimary ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final isSelected = selectedCategory == categories[index]['name'];
        return GestureDetector(
          onTap: () => _filterByCategory(categories[index]['name']!),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    image: DecorationImage(
                      image: AssetImage(categories[index]['icon']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                categories[index]['name']!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunctionalSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => selectedState = value);
              _fetchProducts();
            },
            itemBuilder: (context) => nigeriaStates
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
                      selectedState,
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
                    onSubmitted: (_) => _fetchProducts(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "I am looking for...",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _fetchProducts,
                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE85D22),
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

  Widget _buildLanguageDropdown(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final Map<String, String> languages = {
      "English": "en",
      "Spanish": "es",
      "French": "fr",
    };

    String currentLangName = languages.entries
        .firstWhere((e) => e.value == languageProvider.locale.languageCode, 
            orElse: () => languages.entries.first)
        .key;

    return PopupMenuButton<String>(
<<<<<<< HEAD
      onSelected: (value) => setState(() => selectedLanguage = value),
      itemBuilder: (context) => languageCodes.keys
          .map((l) => PopupMenuItem(value: l, child: Text(l)))
          .toList(),
=======
      onSelected: (value) {
        languageProvider.setLanguage(Locale(languages[value]!));
      },
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
<<<<<<< HEAD
              languageCodes[selectedLanguage] ?? "EN",
=======
              currentLangName.substring(0, 2).toUpperCase(),
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
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
<<<<<<< HEAD
=======
      itemBuilder: (context) => languages.keys
          .map((l) => PopupMenuItem(value: l, child: Text(l)))
          .toList(),
>>>>>>> d31130d9eb82421616f5a6d72b8f40ba45790ed3
    );
  }

  Widget _buildTrendingSection() {
    return Row(
      children: [
        const Text(
          "Trending",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}
