import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Callback type for notifying auth expiry (triggers logout).
typedef OnAuthExpired = void Function();

/// Base HTTP service for all API calls.
///
/// - Adds JWT token to `Authorization` header automatically.
/// - Parses JSON responses.
/// - Auto-refreshes token on 401 before retrying once.
/// - Provides GET, POST, PUT, DELETE helpers.
class ApiService {
  static const String _tokenKey = 'auth_token';

  /// Set this from AuthController so ApiService can force-logout when
  /// refresh also fails.
  static OnAuthExpired? onAuthExpired;

  /// Whether a token refresh is already in progress (prevents loops).
  static bool _isRefreshing = false;

  /// Get stored JWT token.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Build headers with optional auth token.
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Build a full URL from an endpoint path.
  static Uri _uri(String endpoint, [Map<String, String>? queryParams]) {
    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$base$path';
    return Uri.parse(fullUrl).replace(queryParameters: queryParams);
  }

  // ─── GET ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    Future<Map<String, dynamic>> doRequest() async {
      final uri = _uri(endpoint, queryParams);
      final headers = await _headers(withAuth: withAuth);
      final response = await http.get(uri, headers: headers);
      return _parseResponse(response);
    }

    if (withAuth) return _withAutoRefresh(doRequest);
    return doRequest();
  }

  // ─── POST ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    Future<Map<String, dynamic>> doRequest() async {
      final uri = _uri(endpoint);
      final headers = await _headers(withAuth: withAuth);

      print('📤 POST $uri');

      try {
        final response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 30));
        return _parseResponse(response);
      } catch (e) {
        print('❌ POST Error: $e');
        return {
          'success': false,
          'message': 'Tidak dapat terhubung ke server',
        };
      }
    }

    if (withAuth) return _withAutoRefresh(doRequest);
    return doRequest();
  }

  // ─── PUT ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    Future<Map<String, dynamic>> doRequest() async {
      final uri = _uri(endpoint);
      final headers = await _headers(withAuth: withAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    }

    if (withAuth) return _withAutoRefresh(doRequest);
    return doRequest();
  }

  // ─── DELETE ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    Future<Map<String, dynamic>> doRequest() async {
      final uri = _uri(endpoint, queryParams);
      final headers = await _headers(withAuth: withAuth);
      final response = await http.delete(uri, headers: headers);
      return _parseResponse(response);
    }

    if (withAuth) return _withAutoRefresh(doRequest);
    return doRequest();
  }

  // ─── Response parsing ─────────────────────────────────────────────

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      print('API Response - Status: ${response.statusCode}');
      print('API Response - Body: ${response.body}');
      
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Check HTTP status code
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print('API Error: ${response.statusCode}');
        return {
          'success': false,
          'message': json['message'] ?? 'Server error (${response.statusCode})',
          '_statusCode': response.statusCode,
        };
      }
      
      return json;
    } catch (e) {
      print('API Parse Error: $e');
      return {
        'success': false,
        'message': 'Gagal memproses respons server',
      };
    }
  }

  // ─── Token Refresh ────────────────────────────────────────────────

  /// Try to refresh the JWT token. Returns `true` if successful.
  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return false;

      final uri = _uri('/refresh-token');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data']?['token'] != null) {
          final newToken = json['data']['token'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          print('🔄 Token refreshed successfully');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Wraps any API call: if it returns 401, tries to refresh and retry once.
  static Future<Map<String, dynamic>> _withAutoRefresh(
    Future<Map<String, dynamic>> Function() apiCall,
  ) async {
    final result = await apiCall();

    // If 401 and we have a token, attempt refresh
    if (result['_statusCode'] == 401 && !_isRefreshing) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request with the new token
        final retryResult = await apiCall();
        retryResult.remove('_statusCode');
        return retryResult;
      } else {
        // Refresh failed — force logout
        onAuthExpired?.call();
      }
    }

    result.remove('_statusCode');
    return result;
  }
}
