class LoginModel {
  String email;
  String password;

  LoginModel({required this.email, required this.password});

  // Convert to Map for API calls if needed
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
