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

  static const String _storageBase = 'https://sbraisolutions.com/storage/';

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

  /// Returns the first image or empty string
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  /// Converts raw path to full URL (if needed)
  static String _toFullUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '$_storageBase$raw';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // ── Extract Images ─────────────────────────────────────────────────────
    List<String> images = [];

    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .map((img) {
            if (img is Map<String, dynamic>) {
              // Prioritize 'url' (full URL) as returned by your API
              final url = img['url']?.toString() ?? '';
              if (url.isNotEmpty) return url;

              // Fallback to 'path'
              final path = img['path']?.toString() ?? '';
              return _toFullUrl(path);
            }
            return _toFullUrl(img.toString());
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // ── Extract Display Name ───────────────────────────────────────────────
    String extractDisplayName(Map<String, dynamic> json) {
      if (json['vendor'] != null && json['vendor'] is Map) {
        final v = json['vendor'] as Map<String, dynamic>;
        return v['business_name']?.toString() ??
            v['full_name']?.toString() ??
            v['name']?.toString() ??
            'Sbrai Vendor';
      }
      return json['full_name']?.toString() ??
          json['name']?.toString() ??
          'Sbrai Vendor';
    }

    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),

      // API uses 'title'
      name:
          json['title']?.toString().trim() ??
          json['name']?.toString().trim() ??
          'Untitled',

      location: json['location']?.toString() ?? 'Nigeria',

      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,

      priceUnit: json['price_unit']?.toString(),

      description: json['description']?.toString(),

      vendorName: json['vendor'] != null && json['vendor'] is Map
          ? ((json['vendor'] as Map)['business_name']?.toString() ??
                (json['vendor'] as Map)['full_name']?.toString() ??
                (json['vendor'] as Map)['name']?.toString() ??
                'Sbrai Vendor')
          : 'Sbrai Vendor',

      vendorId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0'),

      vendorPhone: json['vendor'] != null && json['vendor'] is Map
          ? (json['vendor'] as Map)['phone']?.toString()
          : null,

      userName: extractDisplayName(json),

      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,

      imageUrls: images,

      category: json['category'] != null && json['category'] is Map
          ? (json['category'] as Map)['name']?.toString() ?? 'General'
          : json['category']?.toString() ?? 'General',

      createdAt: json['created_at']?.toString(),

      chatId: json['chat_id'] is int
          ? json['chat_id']
          : int.tryParse(json['chat_id']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
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
