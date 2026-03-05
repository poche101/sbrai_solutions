class VendorModel {
  String fullName;
  String email;
  String phoneNumber;
  String businessName;
  String nin; // Changed from businessId
  String businessAddress;
  String password;

  VendorModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.businessName,
    required this.nin,
    required this.businessAddress,
    required this.password,
  });
}
