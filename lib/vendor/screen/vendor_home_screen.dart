import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/buyer/product_model.dart';
import 'package:sbrai_solutions/vendor/vendor_menu.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedState = "All Nigeria";
  String selectedLanguage = "English";
  String? selectedCategory; // Track the clicked category
  final TextEditingController _searchController = TextEditingController();

  // Mock data - In a real app, this would come from an API
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  int currentPage = 1;
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
    // Initialize with all products (empty or fetched)
    displayedProducts = allProducts;
  }

  void _filterByCategory(String categoryName) {
    setState(() {
      selectedCategory = categoryName;
      // Logic: Filter the list based on the category name
      displayedProducts = allProducts
          .where((p) => p.category.toLowerCase() == categoryName.toLowerCase())
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          _buildLanguageDropdown(),
          const SizedBox(width: 8),
          const Icon(Icons.person_outline, color: Colors.black87),
          const Center(
            child: Text(
              "  Vendor   ",
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAdScreen()),
          );
        },
        backgroundColor: const Color(0xFFE85D22),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
                  Text(
                    selectedCategory == null
                        ? "Recommended for You"
                        : "Results for $selectedCategory",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedCategory != null)
                    TextButton(
                      onPressed: () => setState(() {
                        selectedCategory = null;
                        displayedProducts = allProducts;
                      }),
                      child: const Text(
                        "Clear Filter",
                        style: TextStyle(color: Colors.blue),
                      ),
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
          onTap: () => _filterByCategory(categories[index]['name']!),
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
    // Map full language names to 2-letter codes for the display
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
              languageCodes[selectedLanguage] ?? "NG",
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
        const PopupMenuItem(value: "Hausa", child: Text("Harshen Hausa")),
        const PopupMenuItem(value: "Igbo", child: Text("Asụsụ Igbo")),
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
