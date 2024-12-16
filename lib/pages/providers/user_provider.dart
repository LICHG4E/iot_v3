import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  List<dynamic> devicesData = [];

  User? get user => _user;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    if (_user != null) {
      await _user!.reload(); // Reload user data from Firebase
      _user = FirebaseAuth.instance.currentUser; // Fetch updated user object
      notifyListeners(); // Notify listeners to refresh UI
    }
  }
}
