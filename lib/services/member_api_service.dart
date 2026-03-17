import 'package:http/http.dart' as http;
import '../models/member.dart';
import 'api_service.dart';

/// Handles member-related API calls for server sync.
class MemberApiService {
  /// POST /member/create
  Future<({bool success, String message})> createMember(Member member) async {
    try {
      final json = await ApiService.post(
        '/member/create',
        body: member.toJson(),
      );
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';
      return (success: success, message: message);
    } on http.ClientException {
      return (success: false, message: 'Tidak dapat terhubung ke server');
    } catch (e) {
      return (success: false, message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// PUT /member/update
  Future<({bool success, String message})> updateMember(Member member) async {
    try {
      final json = await ApiService.put(
        '/member/update',
        body: member.toJson(),
      );
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';
      return (success: success, message: message);
    } on http.ClientException {
      return (success: false, message: 'Tidak dapat terhubung ke server');
    } catch (e) {
      return (success: false, message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// DELETE /member/delete?id=...
  Future<({bool success, String message})> deleteMember(String id) async {
    try {
      final json = await ApiService.delete('/member/delete?id=$id');
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';
      return (success: success, message: message);
    } on http.ClientException {
      return (success: false, message: 'Tidak dapat terhubung ke server');
    } catch (e) {
      return (success: false, message: 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// GET /member/list
  Future<({bool success, String message, List<Member> members})>
      getMembers() async {
    try {
      final json = await ApiService.get('/member/list');
      final success = json['success'] as bool? ?? false;
      final message = json['message'] as String? ?? '';
      if (success && json['data'] != null) {
        final data = json['data'] as List<dynamic>;
        final members = data
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList();
        return (success: true, message: message, members: members);
      }
      return (success: true, message: message, members: <Member>[]);
    } on http.ClientException {
      return (
        success: false,
        message: 'Tidak dapat terhubung ke server',
        members: <Member>[],
      );
    } catch (e) {
      return (
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
        members: <Member>[],
      );
    }
  }
}
