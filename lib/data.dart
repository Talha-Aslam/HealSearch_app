class AppData {
  static final _appData = AppData._internal();
  bool isLoggedIn = true;

  // ignore: non_constant_identifier_names
  String Email = "You are not logged in";

  factory AppData() {
    return _appData;
  }

  AppData._internal();
}

final appData = AppData();
