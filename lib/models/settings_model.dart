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
    this.showPhoneNumber = true,
    this.allowMessages = true,
    this.language = 'English',
    this.currency = 'Nigerian Naira (₦)',
  });

  static SettingsModel fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      newListings: json['notif_new_listings'] ?? true,
      priceDrops: json['notif_price_drops'] ?? true,
      messages: json['notif_messages'] ?? true,
      promotions: json['notif_promotions'] ?? false,
      showOnlineStatus: json['privacy_show_online'] ?? true,
      showPhoneNumber: json['privacy_show_phone'] ?? true,
      allowMessages: json['privacy_allow_msgs'] ?? true,
      language: json['language'] ?? 'English',
      currency: json['currency'] ?? 'Nigerian Naira (₦)',
    );
  }

  Map<String, dynamic> toJson() => {
    'notif_new_listings': newListings,
    'notif_price_drops': priceDrops,
    'notif_messages': messages,
    'notif_promotions': promotions,
    'privacy_show_online': showOnlineStatus,
    'privacy_show_phone': showPhoneNumber,
    'privacy_allow_msgs': allowMessages,
  };

  // Returns a new instance with only the specified fields changed.
  // Used by SettingsScreen to apply optimistic updates cleanly.
  SettingsModel copyWith({
    bool? newListings,
    bool? priceDrops,
    bool? messages,
    bool? promotions,
    bool? showOnlineStatus,
    bool? showPhoneNumber,
    bool? allowMessages,
    String? language,
    String? currency,
  }) {
    return SettingsModel(
      newListings: newListings ?? this.newListings,
      priceDrops: priceDrops ?? this.priceDrops,
      messages: messages ?? this.messages,
      promotions: promotions ?? this.promotions,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      allowMessages: allowMessages ?? this.allowMessages,
      language: language ?? this.language,
      currency: currency ?? this.currency,
    );
  }
}
