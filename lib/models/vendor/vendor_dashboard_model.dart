import 'package:flutter/material.dart';

class VendorData {
  final String activeListings;
  final String totalViews;
  final String messages;
  final String totalSales;
  final double voucherBalance;
  final List<ActivityItem> activities;
  final List<ProductItem> products;

  VendorData({
    required this.activeListings,
    required this.totalViews,
    required this.messages,
    required this.totalSales,
    required this.voucherBalance,
    required this.activities,
    this.products = const [],
  });
}

class ProductItem {
  final String title;
  final String price;
  final String imageUrl;
  final int views;
  final int favorites;
  final int chats;
  final String category;

  ProductItem({
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.views,
    required this.favorites,
    required this.chats,
    required this.category,
  });
}

class ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  ActivityItem(this.icon, this.color, this.title, this.time);
}
