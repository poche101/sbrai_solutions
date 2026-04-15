class Product {
  final int? id; // Added ID for favorite tracking and detail navigation
  final String name;
  final String location;
  final double price;
  final String vendorName;
  final double rating;
  final String imageUrl;
  final String category;

  Product({
    this.id, // Added to constructor
    required this.name,
    required this.location,
    required this.price,
    required this.vendorName,
    required this.rating,
    required this.imageUrl,
    required this.category,
  });

  // This factory constructor converts the JSON from your ProductService into a Product object
  factory Product.fromJson(Map<String, dynamic> json) {
    // Define your server's storage path
    const String storageBaseUrl = "https://sbraisolutions.com/api/storage/";

    return Product(
      // 1. Map the 'id' from the API
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),

      // 2. Mapping 'title' from API to 'name' in Model
      name: json['title'] != null && json['title'].toString().isNotEmpty
          ? json['title']
          : (json['slug'] ?? 'Unknown Product').toString().replaceAll('-', ' '),

      location: json['location'] ?? 'Nigeria',

      // 3. Handling price conversion safely
      price: double.tryParse(json['price'].toString()) ?? 0.0,

      // 4. Checking if vendor object exists
      vendorName: json['vendor'] != null && json['vendor'] is Map
          ? json['vendor']['name']
          : 'Sbrai Vendor',

      // 5. Handling rating safely
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,

      /**
       * 6. Extracting the first image from the 'photos' array.
       * Concatenating storageBaseUrl with the relative path string.
       */
      imageUrl: (json['photos'] != null && (json['photos'] as List).isNotEmpty)
          ? storageBaseUrl + json['photos'][0].toString()
          : 'assets/images/placeholder.jpg',

      // 7. Mapping the category name
      category: json['category'] != null && json['category'] is Map
          ? json['category']['name']
          : 'General',
    );
  }
}
