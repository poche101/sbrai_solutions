class Product {
  final String name;
  final String location;
  final double price;
  final String vendorName;
  final double rating;
  final String imageUrl;
  final String category; // <--- Add this line

  Product({
    required this.name,
    required this.location,
    required this.price,
    required this.vendorName,
    required this.rating,
    required this.imageUrl,
    required this.category, // <--- Add this to the constructor
  });
}
