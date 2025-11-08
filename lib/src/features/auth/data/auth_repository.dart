import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository() : _client = Supabase.instance.client;

  final SupabaseClient _client;
  static const _userCacheKey = 'cocool.currentUser';

  Future<AppUser?> getPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_userCacheKey);
    return AppUser.fromJson(cached);
  }

  Future<void> persistUser(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_userCacheKey);
    } else {
      await prefs.setString(_userCacheKey, user.toJson());
    }
  }

  Future<AppUser?> fetchUserById(String id) async {
    final res = await _client
        .from('app_users')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(res));
  }

  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final res = await _client
        .from('app_users')
        .select()
        .eq('email', email)
        .eq('password', password)
        .maybeSingle();
    if (res == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(res));
  }

  Future<String?> emailExists(String email) async {
    final res = await _client
        .from('app_users')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    if (res == null) return null;
    return res['id']?.toString();
  }

  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String password,
    String? position,
    int? age,
    String role = 'staff',
  }) async {
    final insert = await _client
        .from('app_users')
        .insert({
          'full_name': fullName,
          'email': email,
          'password': password,
          'position': position,
          'age': age,
          'role': role,
        })
        .select()
        .maybeSingle();

    if (insert == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(insert));
  }

  Future<List<AppUser>> listUsers({String? role}) async {
    final base = _client.from('app_users').select();
    final filtered = role != null ? base.eq('role', role) : base;
    final result = await filtered.order('full_name');
    return (result as List)
        .map((item) => AppUser.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<bool> deleteUser(String id) async {
    final response = await _client
        .from('app_users')
        .delete()
        .eq('id', id)
        .select('id')
        .maybeSingle();
    return response != null;
  }

  Future<AppUser?> updateUser(
    AppUser user, {
    String? fullName,
    int? age,
    String? position,
    String? avatarUrl,
    String? role,
  }) async {
    final updated = await _client
        .from('app_users')
        .update({
          if (fullName != null) 'full_name': fullName,
          if (age != null) 'age': age,
          if (position != null) 'position': position,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (role != null) 'role': role,
        })
        .eq('id', user.id)
        .select()
        .maybeSingle();
    if (updated == null) return null;
    return AppUser.fromMap(Map<String, dynamic>.from(updated));
  }

  Future<String?> uploadAvatar({
    required String userId,
    required Uint8List data,
    required String fileExtension,
  }) async {
    final normalizedExtension = fileExtension.toLowerCase().replaceAll('.', '');
    final contentType = switch (normalizedExtension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };

    final objectPath =
        'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    try {
      await _client.storage
          .from('avatars')
          .uploadBinary(
            objectPath,
            data,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
              cacheControl: '3600',
            ),
          );
    } catch (_) {
      return null;
    }

    return _client.storage.from('avatars').getPublicUrl(objectPath);
  }
}
