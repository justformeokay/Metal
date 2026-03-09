import 'user_model.dart';

/// Generic API response wrapper for auth endpoints.
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final int? userId;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.userId,
  });

  /// Parse login response.
  /// { "success": true, "message": "...", "data": { "token": "...", "user": {...} } }
  factory AuthResponse.fromLoginJson(Map<String, dynamic> json) {
    print('🔍 Parsing login response: $json');
    final data = json['data'] as Map<String, dynamic>?;
    final success = json['success'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    
    print('Success: $success, Message: $message, HasData: ${data != null}');
    
    return AuthResponse(
      success: success,
      message: message,
      token: data?['token'] as String?,
      user: data?['user'] != null
          ? UserModel.fromJson(data!['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Parse register response.
  /// The PHP API returns token + user on successful registration (auto-login).
  /// { "success": true, "message": "...", "data": { "token": "...", "user": {...} } }
  factory AuthResponse.fromRegisterJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AuthResponse(
      success: json['success'] as bool,
      message: json['message'] as String? ?? '',
      token: data?['token'] as String?,
      user: data?['user'] != null
          ? UserModel.fromJson(data!['user'] as Map<String, dynamic>)
          : null,
      userId: data?['user']?['id'] as int?,
    );
  }

  /// Parse forgot password response.
  /// { "success": true, "message": "..." }
  factory AuthResponse.fromForgotJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
