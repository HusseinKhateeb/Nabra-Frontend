import 'package:flutter/foundation.dart';

class AuthSessionNotifier extends ChangeNotifier {
  void markLoggedOut() {
    notifyListeners();
  }
}

final AuthSessionNotifier authSessionNotifier = AuthSessionNotifier();