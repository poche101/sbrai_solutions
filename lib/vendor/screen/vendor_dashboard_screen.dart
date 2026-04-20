import 'package:flutter/material.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

// 1. DATA MODELS
class VendorData {
  final String activeListings;
  final String totalViews;
  final String messages;
  final String totalSales;
  final double voucherBalance;
  final List<ActivityItem> activities;
  final List<ProductItem> products;

  VendorData({
    required this.activeListings,
    required this.totalViews,
    required this.messages,
    required this.totalSales,
    required this.voucherBalance,
    required this.activities,
    this.products = const [],
  });
}

class ProductItem {
  final String title;
  final String price;
  final String imageUrl;
  final int views;
  final int favorites;
  final int chats;
  final String category;

  ProductItem({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.views,
    required this.favorites,
    required this.chats,
    required this.category,
  });
}

class ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  ActivityItem(this.icon, this.color, this.title, this.time);
}

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late VendorData currentData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDashboardData() {
    // Demo Data: Populate with items to see the "My Listings" UI
    List<ProductItem> myProducts = [
      ProductItem(
        title: "Modern Cement Mixer",
        price: "₦ 250,000",
        imageUrl:
            "https://images.unsplash.com/photo-1589939705384-5185138a0470?q=80&w=500",
        views: 124,
        favorites: 12,
        chats: 5,
        category: "Machinery",
      ),
      ProductItem(
        title: "High-Grade Steel Rods",
        price: "₦ 45,000",
        imageUrl:
            "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=500",
        views: 89,
        favorites: 8,
        chats: 2,
        category: "Materials",
      ),
    ];

    currentData = VendorData(
      activeListings: myProducts.length.toString(),
      totalViews: "213",
      messages: "7",
      totalSales: "₦ 0",
      voucherBalance: 5000.00,
      products: myProducts,
      activities: [
        ActivityItem(
          Icons.visibility,
          Colors.blue,
          'New view on Cement Mixer',
          '2 mins ago',
        ),
        ActivityItem(
          Icons.chat_bubble,
          Colors.green,
          'New message from John',
          '15 mins ago',
        ),
        ActivityItem(
          Icons.favorite,
          Colors.red,
          'Someone liked your listing',
          '1 hour ago',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Vendor Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [_buildPostAdButton(context)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadDashboardData()),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    currentData.activeListings,
                    'Active Listings',
                    Icons.inventory_2_outlined,
                    Colors.deepOrangeAccent,
                  ),
                  _buildStatCard(
                    currentData.totalViews,
                    'Total Views',
                    Icons.visibility_outlined,
                    Colors.blueAccent,
                  ),
                  _buildStatCard(
                    currentData.messages,
                    'Messages',
                    Icons.chat_bubble_outline,
                    Colors.green,
                  ),
                  _buildStatCard(
                    currentData.totalSales,
                    'Total Sales',
                    Icons.attach_money_outlined,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Custom Tab Bar
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() {}),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.black,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelColor: Colors.black54,
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "My Listings"),
                    Tab(text: "Analytics"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Body
              _buildDynamicTabContent(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTabContent() {
    switch (_tabController.index) {
      case 0:
        return Column(
          children: [
            _buildVoucherSection(currentData.voucherBalance),
            const SizedBox(height: 24),
            _buildSectionHeader("Recent Activity", showViewAll: false),
            _buildActivityCard(currentData.activities),
            const SizedBox(height: 24),
            _buildSectionHeader("Quick Actions", showViewAll: false),
            _buildQuickActions(context),
          ],
        );
      case 1:
        return currentData.products.isEmpty
            ? _buildEmptyState("You haven't uploaded any products yet.")
            : Column(
                children: currentData.products
                    .map((p) => _buildProductCard(p))
                    .toList(),
              );
      case 2:
        return _buildAnalyticsView();
      default:
        return const SizedBox();
    }
  }

  // --- UPDATED MY LISTINGS UI ---
  Widget _buildProductCard(ProductItem product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              product.imageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 110,
                height: 110,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price,
                  style: const TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                // Engagement Metrics
                Row(
                  children: [
                    _iconStat(Icons.visibility_outlined, "${product.views}"),
                    const SizedBox(width: 12),
                    _iconStat(Icons.favorite_border, "${product.favorites}"),
                    const SizedBox(width: 12),
                    _iconStat(Icons.chat_bubble_outline, "${product.chats}"),
                    const Spacer(),
                    _buildBadge("Active", Colors.green.shade600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- ANALYTICS UI ---
  Widget _buildAnalyticsView() {
    final int profileViews = int.tryParse(currentData.totalViews) ?? 0;
    final int activeListings = int.tryParse(currentData.activeListings) ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Performance Overview",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildProgressBar(
                "Profile Views",
                profileViews,
                (profileViews / 1000).clamp(0.0, 1.0),
                Colors.deepOrangeAccent,
              ),
              _buildProgressBar(
                "Active Listings",
                activeListings,
                (activeListings / 50).clamp(0.0, 1.0),
                Colors.blueAccent,
              ),
              _buildProgressBar("Response Rate", "85%", 0.85, Colors.green),
              _buildProgressBar(
                "Customer Satisfaction",
                "4.8/5.0",
                0.96,
                Colors.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Top Performing Listings", showViewAll: false),
        currentData.products.isEmpty
            ? _buildEmptyState("No performance data available yet.")
            : Column(
                children: currentData.products
                    .take(2)
                    .map((p) => _buildProductCard(p))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildProgressBar(
    String label,
    dynamic value,
    double progress,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSED UI HELPER METHODS ---
  Widget _buildPostAdButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAdScreen()),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7043),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.add, size: 18, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Post Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE5DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE5DE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_num_outlined,
                  color: Color(0xFFFF7043),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ad Voucher',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Use for ad promotions',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              _buildBadge("Active", Colors.green.shade600),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE5DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '₦${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7043),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<ActivityItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  entry.value.icon,
                  color: entry.value.color,
                  size: 20,
                ),
                title: Text(
                  entry.value.title,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  entry.value.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              if (entry.key < items.length - 1)
                Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _actionBtn(
          Icons.add,
          "Post New Ad",
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAdScreen()),
          ),
        ),
        _actionBtn(Icons.people_outline, "View Messages", () {}),
        _actionBtn(
          Icons.analytics_outlined,
          "Analytics",
          () => _tabController.animateTo(2),
        ),
        _actionBtn(
          Icons.inventory_2_outlined,
          "Manage Listings",
          () => _tabController.animateTo(1),
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showViewAll = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (showViewAll)
            TextButton(
              onPressed: () {},
              child: const Text("View All", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
