import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/store_service.dart';

/// Manages authentication state across the app.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService();

  AuthController() {
    // Wire up auto-logout when refresh token fails
    ApiService.onAuthExpired = _handleAuthExpired;
  }

  // ─── State ───────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _needsStoreSetup = false;
  String? _errorMessage;
  String? _successMessage;
  UserModel? _user;
  String? _token;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get needsStoreSetup => _needsStoreSetup;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserModel? get user => _user;
  String? get token => _token;

  // SharedPreferences keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // ─── Initialisation ─────────────────────────────────────────────────

  /// Check stored token on app start. Returns `true` if already logged in.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedUser = prefs.getString(_userKey);

    if (storedToken != null && storedUser != null) {
      _token = storedToken;
      _user = UserModel.fromJson(
        jsonDecode(storedUser) as Map<String, dynamic>,
      );
      _isLoggedIn = true;

      // Switch to this user's database
      await DatabaseService().switchUser(_user!.id);

      // Check if user already has a store
      await _checkStoreSetup();

      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── LOGIN ──────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearMessages();

    try {
      final request = LoginRequest(email: email, password: password);
      final AuthResponse response = await _authService.login(request);
      print("Login response: ${response}"); // Debug log

      if (response.success) {
        _token = response.token;
        _user = response.user;
        _isLoggedIn = true;
        await _persistSession();

        // Switch to this user's database
        await DatabaseService().switchUser(_user!.id);

        // Check if user already has a store
        await _checkStoreSetup();

        _successMessage = response.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi nanti.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── REGISTER ───────────────────────────────────────────────────────

  /// Register and auto-login (the PHP API returns a token on registration).
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    clearMessages();

    // Client-side validation before hitting the API
    if (password != confirmPassword) {
      _errorMessage = 'Password dan konfirmasi tidak cocok';
      _setLoading(false);
      return false;
    }

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
      final AuthResponse response = await _authService.register(request);

      if (response.success) {
        // The API returns token + user on register → auto-login
        if (response.token != null && response.user != null) {
          _token = response.token;
          _user = response.user;
          _isLoggedIn = true;
          _needsStoreSetup = true; // New user always needs store setup
          await _persistSession();

          // Switch to this user's database
          await DatabaseService().switchUser(_user!.id);
          _successMessage = response.message;
          notifyListeners();
          return true;
        }

        // Fallback: registration succeeded but no token (shouldn't happen)
        _successMessage = response.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi nanti.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── FORGOT PASSWORD ───────────────────────────────────────────────

  /// POST /api/forgot-password — sends OTP to [email].
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    clearMessages();

    try {
      final AuthResponse response =
          await _authService.forgotPassword(email);

      if (response.success) {
        _successMessage = response.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi nanti.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── VERIFY OTP ────────────────────────────────────────────────────

  /// POST /api/verify-otp — verifies the 6-digit OTP.
  /// Returns the [resetToken] string on success, or null on failure.
  Future<String?> verifyOtp(String email, String otpCode) async {
    _setLoading(true);
    clearMessages();

    try {
      final AuthResponse response =
          await _authService.verifyOtp(email, otpCode);

      if (response.success && response.resetToken != null) {
        _successMessage = response.message;
        notifyListeners();
        return response.resetToken;
      } else {
        _errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Kode OTP tidak valid atau sudah kadaluarsa';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi nanti.';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── RESET PASSWORD ────────────────────────────────────────────────

  /// POST /api/reset-password — sets a new password using the [resetToken].
  Future<bool> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    clearMessages();

    if (newPassword != confirmPassword) {
      _errorMessage = 'Password dan konfirmasi tidak cocok';
      _setLoading(false);
      return false;
    }

    try {
      final AuthResponse response = await _authService.resetPassword(
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.success) {
        _successMessage = response.message;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi nanti.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGOUT ─────────────────────────────────────────────────────────

  Future<void> logout() async {
    // Close current user's database before clearing state
    await DatabaseService().closeDatabase();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    _token = null;
    _user = null;
    _isLoggedIn = false;
    _needsStoreSetup = false;
    clearMessages();
    notifyListeners();
  }

  /// Called by ApiService when token refresh fails (401 + refresh 401).
  void _handleAuthExpired() {
    logout();
  }

  /// Mark store setup as complete (called from StoreSetupScreen).
  void markStoreSetupComplete() {
    _needsStoreSetup = false;
    notifyListeners();
  }

  /// Check if user already has a store via API.
  Future<void> _checkStoreSetup() async {
    try {
      final result = await _storeService.getMyStores();
      _needsStoreSetup = result.success && result.stores.isEmpty;
    } catch (_) {
      _needsStoreSetup = false; // Don't block if API fails
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }
  }
}
