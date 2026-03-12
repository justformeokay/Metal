import 'user_model.dart';

/// Generic API response wrapper for auth endpoints.
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final int? userId;
  /// Reset token returned after OTP is verified successfully.
  final String? resetToken;
  /// Email echoed back from the verify-otp endpoint.
  final String? email;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.userId,
    this.resetToken,
    this.email,
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

  /// Parse verify-otp response — returns reset_token + email on success.
  /// { "success": true, "data": { "reset_token": "...", "email": "..." } }
  factory AuthResponse.fromVerifyOtpJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      resetToken: data?['reset_token'] as String?,
      email: data?['email'] as String?,
    );
  }

  /// Parse reset-password response — just success + message.
  /// { "success": true, "message": "..." }
  factory AuthResponse.fromResetPasswordJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
