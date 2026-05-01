import 'package:flutter/material.dart';
import 'package:sbrai_solutions/models/buyer/product_model.dart';
import 'package:sbrai_solutions/vendor/screen/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.product.imageUrls;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Product Details",
          style: TextStyle(
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
                  // Swipable Image Carousel
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

                  // Header Section (Name, Price, Location)
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
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
                              "${widget.product.id ?? '23'}", // Example count from your image
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
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
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

                  // Seller Info
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Seller Information",
                          style: TextStyle(
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
                                        "${widget.product.rating} rating",
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
                            const Text(
                              "Member since Jan 2025",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Safety Tips Section
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
                        const Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Sbrai Safety Tips",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSafetyBullet(
                          "Do not pay in advance until materials are delivered to your site",
                        ),
                        _buildSafetyBullet(
                          "Always inspect products before making payment",
                        ),
                        _buildSafetyBullet(
                          "Meet sellers in public or safe locations",
                        ),
                        _buildSafetyBullet(
                          "Report suspicious activity to Sbrai support",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

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

  Widget _buildBottomActions(BuildContext context) {
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
                label: const Text(
                  "Call Seller",
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        product: widget.product,
                        userName: widget.userName,
                        userInitial: widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Chat Now",
                  style: TextStyle(
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
