import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_profile.dart';
import '../services/database_service.dart';

/// Controller for settings and business profile.
class SettingsController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  BusinessProfile _profile = BusinessProfile();
  ThemeMode _themeMode = ThemeMode.light;

  static const String _themeModeKey = 'theme_mode';

  BusinessProfile get profile => _profile;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Load profile and settings.
  Future<void> load() async {
    _profile = await _db.getBusinessProfile();
    await _loadThemeMode();
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (_themeMode) {
      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_themeModeKey, 'system');
        break;
      default:
        await prefs.setString(_themeModeKey, 'light');
    }
  }

  /// Save business profile.
  Future<void> updateProfile(BusinessProfile profile) async {
    _profile = profile;
    await _db.updateBusinessProfile(profile);
    notifyListeners();
  }

  /// Toggle dark/light mode.
  void toggleThemeMode() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }
}
