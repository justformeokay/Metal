import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'api_service.dart';

/// Handles all authentication API calls against the PHP backend.
class AuthService {
  // ─── LOGIN ──────────────────────────────────────────────────────────

  /// POST /api/login
  /// Authenticate user. Returns token + user on success.
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('📝 Login attempt: ${request.email}');
      final json = await ApiService.post(
        '/login',
        body: request.toJson(),
        withAuth: false,
      );
      print('✅ Login response: $json');
      return AuthResponse.fromLoginJson(json);
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      return AuthResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    } catch (e) {
      print('❌ Login error: $e');
      return AuthResponse(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  // ─── REGISTER ───────────────────────────────────────────────────────

  /// POST /api/register
  /// Create new account. Returns token + user on success (auto-login).
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final json = await ApiService.post(
        '/register',
        body: request.toJson(),
        withAuth: false,
      );
      return AuthResponse.fromRegisterJson(json);
    } on http.ClientException {
      return AuthResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  // ─── FORGOT PASSWORD ───────────────────────────────────────────────

  /// POST /api/forgot-password
  /// Request a password reset token.
  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final json = await ApiService.post(
        '/forgot-password',
        body: {'email': email},
        withAuth: false,
      );
      return AuthResponse.fromForgotJson(json);
    } on http.ClientException {
      return AuthResponse(
        success: false,
        message: 'Tidak dapat terhubung ke server',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }
}
