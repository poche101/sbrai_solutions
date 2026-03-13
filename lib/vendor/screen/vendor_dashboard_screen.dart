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
    this.products = const [], // Default empty
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
    // Note: Empty products list to trigger the "No products" state
    currentData = VendorData(
      activeListings: "0",
      totalViews: "0",
      messages: "0",
      totalSales: "₦",
      voucherBalance: 0.00,
      products: [],
      activities: [
        ActivityItem(Icons.visibility, Colors.blue, '', ''),
        ActivityItem(Icons.chat_bubble, Colors.green, '', ''),
        ActivityItem(Icons.favorite, Colors.red, '', ''),
        ActivityItem(Icons.visibility, Colors.blue, '', ''),
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
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() {}), // Refresh UI on tab change
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "My Listings"),
                    Tab(text: "Analytics"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Body based on Selected Tab
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
      case 0: // Overview
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
      case 1: // My Listings
        return currentData.products.isEmpty
            ? _buildEmptyState("You haven't uploaded any products yet.")
            : Column(
                children: currentData.products
                    .map((p) => _buildProductCard(p))
                    .toList(),
              );
      case 2: // Analytics
        return _buildAnalyticsView();
      default:
        return const SizedBox();
    }
  }

  // --- MY LISTINGS UI ---
  Widget _buildProductCard(ProductItem product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.grey),
                  ],
                ),
                Text(
                  product.price,
                  style: const TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _iconStat(
                      Icons.visibility_outlined,
                      "${product.views} views",
                    ),
                    const SizedBox(width: 12),
                    _iconStat(
                      Icons.favorite_border,
                      "${product.favorites} favorites",
                    ),
                    const SizedBox(width: 12),
                    _iconStat(Icons.chat_outlined, "${product.chats} chats"),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // --- ANALYTICS UI ---
  Widget _buildAnalyticsView() {
    final int profileViews = int.tryParse(currentData.totalViews) ?? 0;
    final int activeListings = int.tryParse(currentData.activeListings) ?? 0;

    final double profileViewsProgress = (profileViews / 1000).clamp(0.0, 1.0);
    final double listingsProgress = (activeListings / 50).clamp(0.0, 1.0);

    const String responseRate = "0%";
    const double responseProgress = 0.0;

    const String satisfactionScore = "0.0/5.0";
    const double satisfactionProgress = 0.0;

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
                profileViewsProgress,
                Colors.deepOrangeAccent,
              ),
              _buildProgressBar(
                "Active Listings",
                activeListings,
                listingsProgress,
                Colors.blueAccent,
              ),
              _buildProgressBar(
                "Response Rate",
                responseRate,
                responseProgress,
                Colors.green,
              ),
              _buildProgressBar(
                "Customer Satisfaction",
                satisfactionScore,
                satisfactionProgress,
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
                    .take(3)
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
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostAdScreen()),
            );
          },
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
              Icon(icon, color: color, size: 28),
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
              _buildBadge("Active", Colors.greenAccent.shade700),
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
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ready to use',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🚀 Promotion Feature Coming Soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          int idx = entry.key;
          ActivityItem item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color, size: 20),
                title: Text(item.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  item.time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              if (idx < items.length - 1)
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
        _actionBtn(Icons.add, "Post New Ad", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostAdScreen()),
          );
        }),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
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
