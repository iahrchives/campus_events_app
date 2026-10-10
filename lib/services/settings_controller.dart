import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// App-wide user preferences (dark mode, notifications, …).
///
/// A simple [ChangeNotifier] singleton so `main.dart` can rebuild the
/// [MaterialApp] when the theme changes, and screens can read/update prefs.
class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  bool _darkMode = false;
  bool get darkMode => _darkMode;

  bool notifications = true;
  bool eventReminders = true;
  bool compactFeed = false;
  String language = 'English';

  void setDarkMode(bool value) {
    _darkMode = value;
    AppColors.dark = value; // re-themes the AppColors getters
    notifyListeners();
  }

  void setNotifications(bool value) {
    notifications = value;
    notifyListeners();
  }

  void setEventReminders(bool value) {
    eventReminders = value;
    notifyListeners();
  }

  void setCompactFeed(bool value) {
    compactFeed = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }
}
