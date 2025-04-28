class AppData {
  static final _appData = AppData._internal();
  bool isLoggedIn = false; // Default to not logged in

  // User data fields
  String Email = "You are not logged in";
  String? userName;
  String? phoneNumber;

  // Set user data after successful login
  void setUserData(String email, String name, String phone) {
    Email = email;
    userName = name;
    phoneNumber = phone;
    isLoggedIn = true;
  }

  // Clear user data at logout
  void clearUserData() {
    isLoggedIn = false;
    Email = "You are not logged in";
    userName = null;
    phoneNumber = null;
  }

  factory AppData() {
    return _appData;
  }

  AppData._internal();
}

final appData = AppData();
