import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/product_model.dart';
// Importing the dedicated BuyersMenu
import 'package:sbrai_solutions/buyer/widgets/buyers_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // SIMULATED LOGIN DATA
  // In a real app, get these from your Auth Provider or Database
  final String userName = "buyer";
  final String userEmail = "johndoe@example.com";

  String selectedState = "All Nigeria";
  String selectedLanguage = "English";
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  bool isLoading = false;

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
    displayedProducts = allProducts;
  }

  /// Opens a pop-up dialog for the selected category.
  void _openCategoryModal(String categoryName, String categoryIcon) {
    final List<Product> categoryProducts = allProducts
        .where((p) => p.category.toLowerCase() == categoryName.toLowerCase())
        .toList();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        clipBehavior: Clip.hardEdge,
        child: _CategoryBottomSheet(
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          products: categoryProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          _buildLanguageDropdown(),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline, color: Colors.black87),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                userName.split(' ')[0],
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFE85D22),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    "What are you looking for?",
                    style: TextStyle(
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
                  const Text(
                    "Recommended for You",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${displayedProducts.length} items",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildDynamicProductCard(displayedProducts[index]),
                childCount: displayedProducts.length,
              ),
            ),
          ),
        ],
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
        return GestureDetector(
          onTap: () => _openCategoryModal(
            categories[index]['name']!,
            categories[index]['icon']!,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
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

  Widget _buildFunctionalSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PopupMenuButton<String>(
            onSelected: (String value) => setState(() => selectedState = value),
            itemBuilder: (BuildContext context) {
              return nigeriaStates.map((String state) {
                return PopupMenuItem<String>(value: state, child: Text(state));
              }).toList();
            },
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "I am looking for...",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 40,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D22),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    final Map<String, String> languageCodes = {
      "English": "EN",
      "French": "FR",
      "Yoruba": "YO",
      "Hausa": "HA",
      "Igbo": "IG",
    };

    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => selectedLanguage = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              languageCodes[selectedLanguage] ?? "EN",
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
      itemBuilder: (context) => [
        const PopupMenuItem(value: "English", child: Text("English")),
        const PopupMenuItem(value: "French", child: Text("Français")),
        const PopupMenuItem(value: "Yoruba", child: Text("Yorùbá")),
        const PopupMenuItem(value: "Hausa", child: Text("Hausa")),
        const PopupMenuItem(value: "Igbo", child: Text("Igbo")),
      ],
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

  Widget _buildDynamicProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
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
                ),
                Text(
                  "📍 ${product.location}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "₦${product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFFE85D22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallButton("Call", Icons.call, false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSmallButton(
                        "Chat",
                        Icons.chat_bubble_outline,
                        true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label, IconData icon, bool isPrimary) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFE85D22) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          padding: EdgeInsets.zero,
          elevation: 0,
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Colors.grey),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Bottom Sheet (Jiji-style modal)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBottomSheet extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final List<Product> products;

  const _CategoryBottomSheet({
    required this.categoryName,
    required this.categoryIcon,
    required this.products,
  });

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  String _sortBy = 'Newest';
  final List<String> _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
  ];

  List<Product> get _sortedProducts {
    final list = List<Product>.from(widget.products);
    if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.82,
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Sort bar
          if (widget.products.isNotEmpty) _buildSortBar(),

          const Divider(height: 1),

          // Product grid or empty state
          Expanded(
            child: widget.products.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          // Category thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              widget.categoryIcon,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: const Color(0xFFE85D22).withOpacity(0.15),
                child: const Icon(Icons.category, color: Color(0xFFE85D22)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${widget.products.length} listing${widget.products.length == 1 ? '' : 's'} available",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          const Text(
            "Sort by:",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sortOptions.map((option) {
                  final isSelected = _sortBy == option;
                  return GestureDetector(
                    onTap: () => setState(() => _sortBy = option),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE85D22)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE85D22)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE85D22).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Color(0xFFE85D22),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No listings yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to list a product\nor service in ${widget.categoryName}!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _sortedProducts;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildModalProductCard(products[index]),
    );
  }

  Widget _buildModalProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                product.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
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
                Text(
                  "📍 ${product.location}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "₦${product.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Color(0xFFE85D22),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallButton("Call", Icons.call, false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildSmallButton(
                        "Chat",
                        Icons.chat_bubble_outline,
                        true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String label, IconData icon, bool isPrimary) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFE85D22) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black,
          padding: EdgeInsets.zero,
          elevation: 0,
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Colors.grey),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
