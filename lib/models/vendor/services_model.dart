class ServiceModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String title;
  final String slug;
  final String? description;
  final double? price;
  final String? priceUnit;
  final String? location;
  final List<ServicePhoto> photos;

  ServiceModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.slug,
    this.description,
    this.price,
    this.priceUnit,
    this.location,
    this.photos = const [],
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract category title (Supports eager-loaded relations from your controller)
    String extractedCategoryName = "General Service";
    if (json['category'] != null) {
      extractedCategoryName =
          json['category']['title']?.toString() ?? "General Service";
    } else if (json['service_category'] != null) {
      extractedCategoryName =
          json['service_category']['title']?.toString() ?? "General Service";
    }

    return ServiceModel(
      id: json['id'] ?? 0,
      // 2. Map service_category_id accurately
      categoryId: json['service_category_id'] != null
          ? int.parse(json['service_category_id'].toString())
          : 0,
      categoryName: extractedCategoryName,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      // 3. Robust price parsing (handles string decimals from MariaDB)
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      priceUnit: json['price_unit'],
      location: json['location'],
      // 4. Map the photos list returned by $service->load('photos')
      photos:
          (json['photos'] as List?)
              ?.map((photo) => ServicePhoto.fromJson(photo))
              .toList() ??
          (json['service_photos'] as List?)
              ?.map((photo) => ServicePhoto.fromJson(photo))
              .toList() ??
          [],
    );
  }
}

class ServicePhoto {
  final int id;
  final String fullUrl;

  ServicePhoto({required this.id, required this.fullUrl});

  factory ServicePhoto.fromJson(Map<String, dynamic> json) {
    // Since your Laravel Model Accessor now returns the full URL via 'image_path',
    // we simply use it directly.
    return ServicePhoto(
      id: json['id'] ?? 0,
      fullUrl: json['image_path'] ?? json['photo'] ?? '',
    );
  }
}
