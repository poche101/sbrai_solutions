import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sbrai_solutions/models/product_model.dart';
import 'package:sbrai_solutions/screens/chat_screen.dart';
import 'package:sbrai_solutions/services/chat_service.dart';
import 'package:sbrai_solutions/buyer_service/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sbrai_solutions/l10n/app_localizations.dart';
import 'package:sbrai_solutions/services/translation_service.dart';
import 'package:sbrai_solutions/providers/language_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String userName;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.userName,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- Translation state ---
  String? _translatedName;
  String? _translatedDescription;
  bool _isTranslating = false;
  Locale? _lastTranslatedLocale;

  @override
  void initState() {
    super.initState();
    // Fetch translation for the initial locale
    _translateDynamicContentIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When the locale changes (provider), re‑translate dynamic texts
    _translateDynamicContentIfNeeded();
  }

  /// Check if the current locale differs from the one we already translated,
  /// and if so, fetch the cloud translations for name & description.
  Future<void> _translateDynamicContentIfNeeded() async {
    final currentLocale = context.read<LanguageProvider>().locale;

    // Already translated for this locale → nothing to do
    if (_lastTranslatedLocale == currentLocale) return;

    _lastTranslatedLocale = currentLocale;
    final targetLang = currentLocale.languageCode;

    // Don't translate if the target language is English (or whatever original)
    // You can skip the API call entirely if you want, but let's be safe.
    if (targetLang == 'en') {
      setState(() {
        _translatedName = null;
        _translatedDescription = null;
        _isTranslating = false;
      });
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final service = TranslationService();
      final results = await Future.wait([
        service.translateText(widget.product.name, targetLang),
        if (widget.product.description != null &&
            widget.product.description!.isNotEmpty)
          service.translateText(widget.product.description!, targetLang)
        else
          Future.value(null),
      ]);

      if (!mounted) return;
      setState(() {
        _translatedName = results[0];
        _translatedDescription = results[1];
        _isTranslating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTranslating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Translation failed. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final apiService = ApiService();
    final token = await apiService.getToken() ?? '';
    final userData = await apiService.getUserData();
    final currentUserId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;

    final vendorName = (widget.product.vendorName?.trim().isNotEmpty == true)
        ? widget.product.vendorName!
        : 'Seller';
    final vendorInitial = vendorName.isNotEmpty
        ? vendorName[0].toUpperCase()
        : 'S';
    final vendorId = widget.product.vendorId ?? 0;
    final chatId = widget.product.chatId ?? 0;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          authToken: token,
          currentUserId: currentUserId,
          otherPartyName: vendorName,
          otherPartyInitial: vendorInitial,
          adTitle: widget.product.name,
          otherPartyId: vendorId,
          service: ChatService(token),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.product.imageUrls;
    final l10n = AppLocalizations.of(context)!;

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
        // No translate icon anymore – language is handled globally
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
                  // Image Carousel
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
                            return images[index].startsWith('http')
                                ? Image.network(
                              images[index],
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                            );
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
                    ],
                  ),

                  // Name / Price / Location
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show translated name if available, otherwise original
                        if (_isTranslating)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(),
                          ),
                        Text(
                          _translatedName ?? widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "₦${widget.product.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFFE85D22),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.product.id ?? ''}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
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

                  // Description
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
                          _translatedDescription ??
                              widget.product.description ??
                              "No description available.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Seller Information
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
                                    : "S",
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
                                      Text(
                                        widget.product.vendorName ??
                                            "Sbrai Vendor",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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
                                        "${widget.product.rating} ${l10n.rating}",
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
                              "${l10n.memberSince} Jan 2025",
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

                  // Safety Tips
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
          _buildBottomActions(context, l10n),
        ],
      ),
    );
  }

  // Helper Widgets (unchanged)
  Widget _buildSafetyBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
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
}