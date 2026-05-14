import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sbrai_solutions/services/vendor/product_service.dart';
import 'package:sbrai_solutions/vendor/ads/products_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class VendorStats {
  final String activeListings;
  final String totalViews;
  final String messages;
  final String totalSales;

  const VendorStats({
    required this.activeListings,
    required this.totalViews,
    required this.messages,
    required this.totalSales,
  });

  factory VendorStats.fromJson(Map<String, dynamic> j) => VendorStats(
    activeListings: j['active_listings']?.toString() ?? '0',
    totalViews: j['total_views']?.toString() ?? '0',
    messages: j['messages']?.toString() ?? '0',
    totalSales: j['total_sales']?.toString() ?? '₦ 0',
  );

  static VendorStats get empty => const VendorStats(
    activeListings: '0',
    totalViews: '0',
    messages: '0',
    totalSales: '₦ 0',
  );
}

class DashboardProduct {
  final int id;
  final String title;
  final String description;
  final String price;
  final double priceRaw;
  final String priceUnit;
  final String imageUrl;
  final List<Map<String, dynamic>> images;
  final int views;
  final int favorites;
  final int chats;
  final String category;
  final int? categoryId;
  final String status;
  final String location;
  final String type;

  const DashboardProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceRaw,
    required this.priceUnit,
    required this.imageUrl,
    required this.images,
    required this.views,
    required this.favorites,
    required this.chats,
    required this.category,
    required this.categoryId,
    required this.status,
    required this.location,
    required this.type,
  });

  factory DashboardProduct.fromJson(Map<String, dynamic> j) => DashboardProduct(
    id: j['id'] as int? ?? 0,
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    price: j['price']?.toString() ?? '₦ 0',
    priceRaw: (j['price_raw'] as num?)?.toDouble() ?? 0,
    priceUnit: j['price_unit']?.toString() ?? '',
    imageUrl: j['image_url']?.toString() ?? '',
    images: ((j['images'] as List?) ?? [])
        .map((img) => Map<String, dynamic>.from(img as Map))
        .toList(),
    views: j['views'] as int? ?? 0,
    favorites: j['favorites'] as int? ?? 0,
    chats: j['chats'] as int? ?? 0,
    category: j['category']?.toString() ?? '',
    categoryId: j['category_id'] as int?,
    status: j['status']?.toString() ?? 'active',
    location: j['location']?.toString() ?? '',
    type: j['type']?.toString() ?? 'product',
  );
}

class ActivityItem {
  final String title;
  final String time;
  final String type;
  final String colorHex;

  const ActivityItem({
    required this.title,
    required this.time,
    required this.type,
    required this.colorHex,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
    title: j['title']?.toString() ?? '',
    time: j['time']?.toString() ?? '',
    type: j['type']?.toString() ?? 'view',
    colorHex: j['color_hex']?.toString() ?? '#2196F3',
  );

  IconData get icon {
    switch (type) {
      case 'favorite':
        return Icons.favorite;
      case 'chat':
        return Icons.chat_bubble;
      default:
        return Icons.visibility;
    }
  }

  Color get color {
    switch (type) {
      case 'favorite':
        return Colors.red;
      case 'chat':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class AnalyticsData {
  final int profileViews;
  final int activeListings;
  final int responseRate;
  final List<DashboardProduct> topListings;

  const AnalyticsData({
    required this.profileViews,
    required this.activeListings,
    required this.responseRate,
    required this.topListings,
  });

  static AnalyticsData get empty => const AnalyticsData(
    profileViews: 0,
    activeListings: 0,
    responseRate: 0,
    topListings: [],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// VendorDashboardScreen
// ══════════════════════════════════════════════════════════════════════════════

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const String _base = 'https://sbraisolutions.com/api/v1';

  late TabController _tabController;

  final ProductService _productService = ProductService();

  VendorStats stats = VendorStats.empty;
  double voucherBalance = 5000;
  List<ActivityItem> activities = [];
  List<DashboardProduct> products = [];
  AnalyticsData analytics = AnalyticsData.empty;

  bool _loadingDashboard = true;
  bool _loadingAnalytics = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.index == 2 && analytics.profileViews == 0) {
          _fetchAnalytics();
        }
      });
    _fetchDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('vendor_auth_token');
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _loadingDashboard = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      if (token == null) throw 'Not authenticated';

      final res = await http
          .get(
            Uri.parse('$_base/vendor/dashboard'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          setState(() {
            stats = VendorStats.fromJson(data['stats'] ?? {});
            final apiBalance =
                (data['voucher_balance'] as num?)?.toDouble() ?? 0;
            voucherBalance = apiBalance > 0 ? apiBalance : 5000;
            activities = ((data['activities'] as List?) ?? [])
                .map((a) => ActivityItem.fromJson(a as Map<String, dynamic>))
                .toList();
            products = ((data['products'] as List?) ?? [])
                .map(
                  (p) => DashboardProduct.fromJson(p as Map<String, dynamic>),
                )
                .toList();
          });
        }
      } else {
        throw 'Server error ${res.statusCode}';
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      debugPrint('❌ Dashboard: $e');
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _loadingAnalytics = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http
          .get(
            Uri.parse('$_base/vendor/analytics'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          setState(() {
            analytics = AnalyticsData(
              profileViews: data['profile_views'] as int? ?? 0,
              activeListings: data['active_listings'] as int? ?? 0,
              responseRate: data['response_rate'] as int? ?? 0,
              topListings: ((data['top_listings'] as List?) ?? [])
                  .map(
                    (p) => DashboardProduct.fromJson(p as Map<String, dynamic>),
                  )
                  .toList(),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Analytics: $e');
    } finally {
      if (mounted) setState(() => _loadingAnalytics = false);
    }
  }

  // Delete Listing
  Future<void> _deleteListing(DashboardProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${product.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _productService.deleteListing(product.id);

      setState(() {
        products.removeWhere((p) => p.id == product.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit Listing
  Future<void> _editListing(DashboardProduct product) async {
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
      }
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditListingScreen(
          product: product,
          token: token,
          baseUrl: _base,
          onSaved: _fetchDashboard, // Full refresh after edit
        ),
      ),
    );
  }

  void _goToManageListings() => _tabController.animateTo(1);

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
        actions: [_postAdButton(context)],
      ),
      body: _loadingDashboard
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7043)),
            )
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _fetchDashboard,
              color: const Color(0xFFFF7043),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 20),
                    _buildTabContent(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final items = [
      (
        stats.activeListings,
        'Active Listings',
        Icons.inventory_2_outlined,
        Colors.deepOrangeAccent,
      ),
      (
        stats.totalViews,
        'Total Views',
        Icons.visibility_outlined,
        Colors.blueAccent,
      ),
      (stats.messages, 'Messages', Icons.chat_bubble_outline, Colors.green),
      (
        stats.totalSales,
        'Total Sales',
        Icons.attach_money_outlined,
        Colors.orange,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: items.map((e) {
        final (value, label, icon, color) = e;
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
                    child: Icon(icon, color: color, size: 22),
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
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelColor: Colors.black54,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'My Listings'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return Column(
          children: [
            _buildVoucherCard(),
            const SizedBox(height: 20),
            _sectionHeader('Recent Activity'),
            activities.isEmpty
                ? _emptyState('No recent activity yet.')
                : _buildActivityList(),
            const SizedBox(height: 20),
            _sectionHeader('Quick Actions'),
            _buildQuickActions(context),
          ],
        );
      case 1:
        return _buildMyListingsTab();
      case 2:
        return _loadingAnalytics
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(color: Color(0xFFFF7043)),
                ),
              )
            : _buildAnalyticsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVoucherCard() {
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
              _badge('Active', Colors.green.shade600),
            ],
          ),
          const SizedBox(height: 16),
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
                  '₦${_formatNumber(voucherBalance.toInt())}',
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

  Widget _buildActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final item = entry.value;
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
              if (entry.key < activities.length - 1)
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
        _quickActionBtn(
          Icons.add,
          'Post New Ad',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          ).then((_) => _fetchDashboard()),
        ),
        _quickActionBtn(Icons.people_outline, 'View Messages', () {}),
        _quickActionBtn(
          Icons.analytics_outlined,
          'Analytics',
          () => _tabController.animateTo(2),
        ),
        _quickActionBtn(
          Icons.inventory_2_outlined,
          'Manage Listings',
          _goToManageListings,
        ),
      ],
    );
  }

  Widget _quickActionBtn(IconData icon, String label, VoidCallback onTap) {
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
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(height: 6),
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

  Widget _buildMyListingsTab() {
    if (products.isEmpty) {
      return Column(
        children: [
          _emptyState("You haven't uploaded any listings yet."),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAdScreen()),
              ).then((_) => _fetchDashboard()),
              icon: const Icon(Icons.add),
              label: const Text('Post Your First Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${products.length} listing${products.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAdScreen()),
              ).then((_) => _fetchDashboard()),
              icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF7043)),
              label: const Text(
                'Add New',
                style: TextStyle(
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...products.map((p) => _buildProductCard(p)),
      ],
    );
  }

  Widget _buildProductCard(DashboardProduct p) {
    final isActive = p.status == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: p.imageUrl.startsWith('http')
                ? Image.network(
                    p.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (p.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.category,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    _badge(
                      isActive ? 'Active' : 'Inactive',
                      isActive ? Colors.green.shade600 : Colors.grey.shade500,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (p.location.isNotEmpty)
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
                          p.location,
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
                const SizedBox(height: 4),
                Text(
                  p.price,
                  style: const TextStyle(
                    color: Color(0xFFFF7043),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _iconStat(Icons.visibility_outlined, '${p.views}'),
                    const SizedBox(width: 10),
                    _iconStat(Icons.favorite_border, '${p.favorites}'),
                    const SizedBox(width: 10),
                    _iconStat(Icons.chat_bubble_outline, '${p.chats}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _editListing(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7043).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: Color(0xFFFF7043),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFFFF7043),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteListing(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 13,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildAnalyticsTab() {
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
                'Performance Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 20),
              _progressBar(
                'Profile Views',
                analytics.profileViews,
                (analytics.profileViews / 1000).clamp(0.0, 1.0),
                Colors.deepOrangeAccent,
              ),
              _progressBar(
                'Active Listings',
                analytics.activeListings,
                (analytics.activeListings / 50).clamp(0.0, 1.0),
                Colors.blueAccent,
              ),
              _progressBar(
                'Response Rate',
                '${analytics.responseRate}%',
                analytics.responseRate / 100,
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionHeader('Top Performing Listings'),
        analytics.topListings.isEmpty
            ? _emptyState('No performance data yet.')
            : Column(
                children: analytics.topListings.map(_buildProductCard).toList(),
              ),
      ],
    );
  }

  Widget _progressBar(
    String label,
    dynamic value,
    double progress,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _emptyState(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _iconStat(IconData icon, String count) => Row(
    children: [
      Icon(icon, size: 13, color: Colors.grey.shade600),
      const SizedBox(width: 3),
      Text(
        count,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _postAdButton(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Center(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostAdScreen()),
        ).then((_) => _fetchDashboard()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7043),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, size: 17, color: Colors.white),
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

  Widget _imgPlaceholder() => Container(
    width: 100,
    height: 100,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );

  String _formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Edit Listing Screen
// ══════════════════════════════════════════════════════════════════════════════

class _EditListingScreen extends StatefulWidget {
  final DashboardProduct product;
  final String token;
  final String baseUrl;
  final VoidCallback onSaved;

  const _EditListingScreen({
    required this.product,
    required this.token,
    required this.baseUrl,
    required this.onSaved,
  });

  @override
  State<_EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<_EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _priceUnitController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late String _selectedStatus;
  bool _isSaving = false;

  static const List<String> _statusOptions = ['active', 'inactive', 'sold'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final rawPrice = p.priceRaw > 0
        ? p.priceRaw.toStringAsFixed(0)
        : p.price.replaceAll(RegExp(r'[₦,\s]'), '');

    _titleController = TextEditingController(text: p.title);
    _priceController = TextEditingController(text: rawPrice);
    _priceUnitController = TextEditingController(text: p.priceUnit);
    _locationController = TextEditingController(text: p.location);
    _descriptionController = TextEditingController(text: p.description);

    _selectedStatus = _statusOptions.contains(p.status) ? p.status : 'active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final result = await ProductService().updateListing(
        id: widget.product.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()),
        priceUnit: _priceUnitController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (result['success'] == true) {
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw result['message'] ?? 'Update failed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF7043),
                      ),
                    )
                  : TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Color(0xFFFF7043),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (widget.product.imageUrl.startsWith('http'))
                Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),

              _buildCard(
                children: [
                  const Text(
                    'Listing Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _label('Title *'),
                  _field(
                    controller: _titleController,
                    hint: 'Enter listing title',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  _label('Location *'),
                  _field(
                    controller: _locationController,
                    hint: 'Enter location',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Location is required'
                        : null,
                  ),
                  _label('Description'),
                  _field(
                    controller: _descriptionController,
                    hint: 'Enter description (optional)',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildCard(
                children: [
                  const Text(
                    'Pricing',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Price (₦) *'),
                            _field(
                              controller: _priceController,
                              hint: 'e.g. 5000',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Price is required';
                                if (double.tryParse(v.trim()) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Unit'),
                            _field(
                              controller: _priceUnitController,
                              hint: 'per bag',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildCard(
                children: [
                  const Text(
                    'Listing Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF1F4F7),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _statusOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  s == 'active'
                                      ? Icons.check_circle_outline
                                      : s == 'sold'
                                      ? Icons.sell_outlined
                                      : Icons.pause_circle_outline,
                                  size: 16,
                                  color: s == 'active'
                                      ? Colors.green
                                      : s == 'sold'
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(s[0].toUpperCase() + s.substring(1)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF1F4F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    ),
  );
}
