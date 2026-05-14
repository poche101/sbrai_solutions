class Product {
  final int? id;
  final String name;
  final String location;
  final double price;
  final String? priceUnit;
  final String? description;
  final String? vendorName;
  final int? vendorId;
  final String? vendorPhone;
  final String userName;
  final double rating;
  final List<String> imageUrls;
  final String category;
  final String? createdAt;
  final int? chatId;

  Product({
    this.id,
    required this.name,
    required this.location,
    required this.price,
    this.priceUnit,
    this.description,
    this.vendorName,
    this.vendorId,
    this.vendorPhone,
    required this.userName,
    required this.rating,
    required this.imageUrls,
    required this.category,
    this.createdAt,
    this.chatId,
  });

  /// Returns the first image or placeholder
  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls[0] : 'assets/images/placeholder.jpg';

  factory Product.fromJson(Map<String, dynamic> json) {
    // ── Extract images ────────────────────────────────────────────────────────
    // API returns: "images": [ { "url": "https://...", ... }, ... ]
    // Fallback:    "photos": [ "https://..." ] (old format)
    List<String> images = [];

    if (json['images'] != null && json['images'] is List) {
      // ✅ New format — each item is an object with a 'url' field
      images = (json['images'] as List)
          .map((img) {
            if (img is Map) {
              return img['url']?.toString() ?? '';
            }
            return img.toString();
          })
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['photos'] != null && json['photos'] is List) {
      // Legacy format — list of path strings
      const String storageBaseUrl = "https://sbraisolutions.com/storage/";
      images = (json['photos'] as List).map((photo) {
        final photoPath = photo.toString();
        return photoPath.startsWith('http')
            ? photoPath
            : storageBaseUrl + photoPath;
      }).toList();
    }

    // ── Vendor name ───────────────────────────────────────────────────────────
    String extractDisplayName(Map<String, dynamic> json) {
      if (json['vendor'] != null && json['vendor'] is Map) {
        final v = json['vendor'] as Map<String, dynamic>;
        return v['business_name']?.toString() ??
            v['full_name']?.toString() ??
            v['name']?.toString() ??
            'Sbrai Vendor';
      }
      return json['full_name']?.toString() ?? 'Sbrai Vendor';
    }

    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),

      name: json['title'] != null && json['title'].toString().isNotEmpty
          ? json['title'].toString()
          : (json['slug'] ?? 'Unknown Product').toString().replaceAll('-', ' '),

      location: json['location']?.toString() ?? 'Nigeria',

      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      priceUnit: json['price_unit']?.toString(),

      description: json['description']?.toString(),

      vendorName: json['vendor'] != null && json['vendor'] is Map
          ? (json['vendor'] as Map)['name']?.toString() ?? 'Sbrai Vendor'
          : 'Sbrai Vendor',

      vendorId:
          json['user_id']
              is int // ✅ API returns user_id not vendor_id
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0'),

      chatId: json['chat_id'] is int
          ? json['chat_id']
          : int.tryParse(json['chat_id']?.toString() ?? '0'),

      userName: extractDisplayName(json),

      vendorPhone: json['vendor'] != null && json['vendor'] is Map
          ? (json['vendor'] as Map)['phone']?.toString()
          : json['vendor_phone']?.toString(),

      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,

      imageUrls: images.isNotEmpty ? images : ['assets/images/placeholder.jpg'],

      category: json['category'] != null && json['category'] is Map
          ? (json['category'] as Map)['name']?.toString() ?? 'General'
          : json['category']?.toString() ?? 'General',

      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'price': price,
      'price_unit': priceUnit,
      'description': description,
      'vendor_name': vendorName,
      'vendor_id': vendorId,
      'vendor_phone': vendorPhone,
      'user_name': userName,
      'rating': rating,
      'image_urls': imageUrls,
      'category': category,
      'created_at': createdAt,
      'chat_id': chatId,
    };
  }
}
