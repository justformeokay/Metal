import 'package:http/http.dart' as http;
import '../models/store_model.dart';
import 'api_service.dart';

/// Handles store-related API calls.
class StoreService {
  /// POST /store/create
  /// Create a new store for the authenticated user.
  Future<({bool success, String message, StoreModel? store})> createStore({
    required String storeName,
    String? phone,
    String? address,
  }) async {
    try {
      final json = await ApiService.post(
        '/store/create',
        body: {
          'store_name': storeName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
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
  }) async {
    try {
      final json = await ApiService.put(
        '/store/update',
        body: {
          'store_id': storeId,
          'store_name': storeName,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
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
