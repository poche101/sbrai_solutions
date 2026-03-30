class SettingsModel {
  bool newListings;
  bool priceDrops;
  bool messages;
  bool promotions;
  bool showOnlineStatus;
  bool showPhoneNumber;
  bool allowMessages;
  String language;
  String currency;

  SettingsModel({
    this.newListings = true,
    this.priceDrops = true,
    this.messages = true,
    this.promotions = false,
    this.showOnlineStatus = true,
    this.showPhoneNumber = false,
    this.allowMessages = true,
    this.language = 'English',
    this.currency = 'USD',
  });

  // MUST BE INSIDE THE CLASS
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      newListings: json['new_listings'] ?? true,
      priceDrops: json['price_drops'] ?? true,
      messages: json['messages'] ?? true,
      promotions: json['promotions'] ?? false,
      showOnlineStatus: json['show_online_status'] ?? true,
      showPhoneNumber: json['show_phone_number'] ?? false,
      allowMessages: json['allow_messages'] ?? true,
      language: json['language'] ?? 'English',
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_listings': newListings,
      'price_drops': priceDrops,
      'messages': messages,
      'promotions': promotions,
      'show_online_status': showOnlineStatus,
      'show_phone_number': showPhoneNumber,
      'allow_messages': allowMessages,
      'language': language,
      'currency': currency,
    };
  }
}
