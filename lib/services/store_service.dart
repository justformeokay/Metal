import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/store_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Handles store-related API calls.
class StoreService {
  /// POST /api/upload/store-logo
  /// Upload store logo and return the file URL.
  Future<({bool success, String message, String? url})> uploadStoreLogo({
    required File logoFile,
    required String storeName,
  }) async {
    try {
      final fileExtension = logoFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExtension);
      final baseUrl = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/upload/store-logo');
      final request = http.MultipartRequest('POST', uri);

      final fileBytes = await logoFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: 'logo.$fileExtension',
          contentType: mimeType != null
              ? http.MediaType.parse(mimeType)
              : http.MediaType('application', 'octet-stream'),
        ),
      );

      request.fields['store_name'] = storeName;

      final token = await ApiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (responseBody.isEmpty) {
        return (
          success: false,
          message: 'Server error: empty response (HTTP ${response.statusCode})',
          url: null,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';

      if (success && json['data'] != null) {
        final url = json['data']['url'] as String?;
        return (success: true, message: message, url: url);
      }

      return (success: false, message: message, url: null);
    } on http.ClientException {
      return (
        success: false,
        message: 'Tidak dapat terhubung ke server',
        url: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        url: null,
      );
    }
  }

  /// Helper: Get MIME type from file extension
  String? _getMimeType(String extension) {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    return mimeTypes[extension];
  }

  /// POST /store/create
  /// Create a new store for the authenticated user.
  Future<({bool success, String message, StoreModel? store})> createStore({
    required String storeName,
    String? businessType,
    String? logoUrl,
    String? phone,
    String? address,
    String? description,
  }) async {
    try {
      final json = await ApiService.post(
        '/store/create',
        body: {
          'store_name': storeName,
          if (businessType != null && businessType.isNotEmpty)
            'business_type': businessType,
          if (logoUrl != null && logoUrl.isNotEmpty) 'logo_url': logoUrl,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );

      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';

      if (success && json['data'] != null) {
        final store =
            StoreModel.fromJson(json['data'] as Map<String, dynamic>);
        return (success: true, message: message, store: store);
      }

      return (success: false, message: message, store: null);
    } on http.ClientException {
      return (
        success: false,
        message: 'Tidak dapat terhubung ke server',
        store: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        store: null,
      );
    }
  }

  /// GET /store/my-store
  /// Get all stores belonging to the authenticated user.
  Future<({bool success, String message, List<StoreModel> stores})>
      getMyStores() async {
    try {
      final json = await ApiService.get('/store/my-store');

      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';

      if (success && json['data'] != null) {
        final data = json['data'] as List<dynamic>;
        final stores = data
            .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return (success: true, message: message, stores: stores);
      }

      return (success: true, message: message, stores: <StoreModel>[]);
    } on http.ClientException {
      return (
        success: false,
        message: 'Tidak dapat terhubung ke server',
        stores: <StoreModel>[],
      );
    } catch (e) {
      return (
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        stores: <StoreModel>[],
      );
    }
  }

  /// PUT /store/update
  /// Update an existing store.
  Future<({bool success, String message, StoreModel? store})> updateStore({
    required int storeId,
    required String storeName,
    String? phone,
    String? address,
    String? description,
    String? logoUrl,
  }) async {
    try {
      final json = await ApiService.put(
        '/store/update',
        body: {
          'store_id': storeId,
          'store_name': storeName,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (description != null) 'description': description,
          if (logoUrl != null) 'logo_url': logoUrl,
        },
      );

      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';

      if (success && json['data'] != null) {
        final store =
            StoreModel.fromJson(json['data'] as Map<String, dynamic>);
        return (success: true, message: message, store: store);
      }

      return (success: false, message: message, store: null);
    } on http.ClientException {
      return (
        success: false,
        message: 'Tidak dapat terhubung ke server',
        store: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        store: null,
      );
    }
  }
}
