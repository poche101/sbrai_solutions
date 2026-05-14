class Product {
  final int? id;
  final String name;
  final String location;
  final double price;
  final String? priceUnit;
  final String? description;
  final String? vendorName;
  final String? vendorPhone;
  final String userName; // This holds 'Full Name' or 'Business Name'
  final double rating;
  final List<String> imageUrls; // Successfully updated to List
  final String category;
  final String? createdAt;
  bool isFavorite;

  Product({
    this.id,
    required this.name,
    required this.location,
    required this.price,
    this.priceUnit,
    this.description,
    required this.vendorName,
    this.vendorPhone,
    required this.userName,
    required this.rating,
    required this.imageUrls,
    required this.category,
    this.createdAt,
    this.isFavorite = false,
  });

  /// --- BACKWARD COMPATIBILITY GETTER ---
  /// This fixes the "getter 'imageUrl' isn't defined" errors in your other files.
  /// It returns the first image from the list or a placeholder if empty.
  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls[0] : 'assets/images/placeholder.jpg';

  factory Product.fromJson(Map<String, dynamic> json) {
    const String storageBaseUrl = "https://sbraisolutions.com/api/storage/";

    // Helper to extract the name from nested vendor object
    String extractDisplayName(Map<String, dynamic> json) {
      if (json['vendor'] != null && json['vendor'] is Map) {
        var v = json['vendor'];
        // Priority: Business Name -> Full Name -> Generic Fallback
        return v['business_name']?.toString() ??
            v['full_name']?.toString() ??
            v['name']?.toString() ??
            'Sbrai Vendor';
      }
      return json['full_name']?.toString() ?? 'Sbrai Vendor';
    }

    // --- IMAGE ARRAY LOGIC ---
    List<String> images = [];
    if (json['photos'] != null && json['photos'] is List) {
      images = (json['photos'] as List).map((photo) {
        String photoPath = photo.toString();
        // If it's already a full URL, use it; otherwise, append base URL
        return photoPath.startsWith('http')
            ? photoPath
            : storageBaseUrl + photoPath;
      }).toList();
    }

    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),

      name: json['title'] != null && json['title'].toString().isNotEmpty
          ? json['title']
          : (json['slug'] ?? 'Unknown Product').toString().replaceAll('-', ' '),

      location: json['location'] ?? 'Nigeria',

      price: double.tryParse(json['price'].toString()) ?? 0.0,

      priceUnit: json['price_unit']?.toString(),

      description: json['description']?.toString(),

      vendorName: json['vendor'] != null && json['vendor'] is Map
          ? json['vendor']['name']?.toString() ?? 'Sbrai Vendor'
          : 'Sbrai Vendor',

      userName: extractDisplayName(json),

      vendorPhone: json['vendor'] != null && json['vendor'] is Map
          ? json['vendor']['phone']?.toString()
          : json['vendor_phone']?.toString(),

      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,

      // Assign the mapped list of images here
      imageUrls: images.isNotEmpty ? images : ['assets/images/placeholder.jpg'],

      category: json['category'] != null && json['category'] is Map
          ? json['category']['name']?.toString() ?? 'General'
          : 'General',

      createdAt: json['created_at']?.toString(),

      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
    );
  }
}
