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
}
