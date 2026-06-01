import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/screens/chat_screen.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/mixins/translation_mixin.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String userName;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.userName = '',
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TranslationMixin<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _translatedVendorName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _performTranslation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performTranslation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Translation ────────────────────────────────────────────────────────────

  Future<void> _performTranslation() async {
    await translateIfNeeded(
      items: [widget.product],
      onTranslate: (targetLang) async {
        setState(() => isTranslating = true);
        try {
          final productKey =
              widget.product.id?.toString() ?? widget.product.name;
          final vendorName = widget.product.vendorName ?? 'Sbrai Vendor';

          final results = await Future.wait([
            translateText(widget.product.name, targetLang),
            if (widget.product.description?.isNotEmpty ?? false)
              translateText(widget.product.description!, targetLang)
            else
              Future.value(null),
            translateText(vendorName, targetLang),
          ]);

          if (mounted) {
            setState(() {
              if (results[0] != null) translatedNames[productKey] = results[0]!;
              if (results[1] != null)
                translatedDescriptions[productKey] = results[1]!;
              _translatedVendorName = results[2];
            });
          }
        } finally {
          if (mounted) setState(() => isTranslating = false);
        }
      },
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < widget.product.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
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

  /// Opens ChatScreen.
  /// Reads currentUserId from ApiService user data cache.
  /// Token is lazy-loaded inside ChatService — no manual fetch needed.
  /// Opens ChatScreen.
  /// Reads currentUserId and authToken from ApiService user data cache.
  Future<void> _openChat(BuildContext context) async {
    final apiService = ApiService();

    // 1. Fetch user data and token in parallel to avoid multiple async delays
    final results = await Future.wait([
      apiService.getUserData(),
      apiService.getToken(),
    ]);

    final userData = results[0] as Map<String, dynamic>? ?? {};
    final token = results[1] as String?;
    final validToken = token ?? '';

    final currentUserId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;

    final vendorName = (widget.product.vendorName?.trim().isNotEmpty == true)
        ? widget.product.vendorName!
        : 'Seller';
    final vendorInitial = vendorName.isNotEmpty
        ? vendorName[0].toUpperCase()
        : 'S';
    final vendorId = widget.product.vendorId ?? 0;
    final chatId = widget.product.chatId ?? 0;

    // 2. Guard check: Ensure the widget is still mounted before navigating
    // after asynchronous delays.
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUserId,
          otherPartyName: vendorName,
          otherPartyInitial: vendorInitial,
          adTitle: widget.product.name,
          otherPartyId: vendorId,
          service: ChatService(currentUserId: currentUserId),
        ),
      ),
    );
  }
  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final images = widget.product.imageUrls;
    final l10n = AppLocalizations.of(context)!;
    final productKey = widget.product.id?.toString() ?? widget.product.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.listingDetails,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image carousel ───────────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: images.isEmpty
                            ? Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) =>
                                    setState(() => _currentPage = index),
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  final url = images[index];
                                  return url.startsWith('http')
                                      ? Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: Colors.grey[100],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFFE85D22),
                                                    ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        )
                                      : Image.asset(url, fit: BoxFit.cover);
                                },
                              ),
                      ),
                      if (images.length > 1 && _currentPage > 0)
                        Positioned(
                          left: 8,
                          child: _buildNavButton(
                            icon: Icons.arrow_back_ios_new,
                            onPressed: _previousPage,
                          ),
                        ),
                      if (images.length > 1 && _currentPage < images.length - 1)
                        Positioned(
                          right: 8,
                          child: _buildNavButton(
                            icon: Icons.arrow_forward_ios,
                            onPressed: _nextPage,
                          ),
                        ),
                      // Page indicator dots
                      if (images.length > 1)
                        Positioned(
                          bottom: 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: i == _currentPage ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _currentPage
                                      ? const Color(0xFFE85D22)
                                      : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── Name / Price / Location ──────────────────────────────
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTranslating)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: Color(0xFFE85D22),
                            ),
                          ),
                        Text(
                          translatedNames[productKey] ?? widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '₦${_formatPrice(widget.product.price)}',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFFE85D22),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.product.priceUnit != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '/ ${widget.product.priceUnit}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.location,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Description ──────────────────────────────────────────
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          translatedDescriptions[productKey] ??
                              widget.product.description ??
                              'No description available.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Seller information ───────────────────────────────────
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sellerInformation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFFFEBE3),
                              child: Text(
                                widget.product.vendorName?.isNotEmpty == true
                                    ? widget.product.vendorName![0]
                                          .toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Color(0xFFE85D22),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _translatedVendorName ??
                                              widget.product.vendorName ??
                                              'Sbrai Vendor',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.product.rating} ${l10n.rating}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.memberSince} Jan 2025',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Safety tips ──────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.safetyTips,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSafetyBullet(l10n.safetyTip1),
                        _buildSafetyBullet(l10n.safetyTip2),
                        _buildSafetyBullet(l10n.safetyTip3),
                        _buildSafetyBullet(l10n.safetyTip4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bottom actions ───────────────────────────────────────────────
          _buildBottomActions(context, l10n),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _buildSafetyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 18),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildBottomActions(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // Call button
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _makePhoneCall(widget.product.vendorPhone ?? '0800000000'),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: Text(
                  l10n.call,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Chat button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  l10n.chat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFD6B3D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num p = price is num ? price : num.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M';
    if (p >= 1000) return '${(p / 1000).toStringAsFixed(0)}K';
    return p.toStringAsFixed(0);
  }
}
