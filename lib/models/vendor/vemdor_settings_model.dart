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
    this.priceDrops = false,
    this.messages = true,
    this.promotions = true,
    this.showOnlineStatus = true,
    this.showPhoneNumber = false,
    this.allowMessages = true,
    this.language = 'English',
    this.currency = 'USD (₦)',
  });
}
