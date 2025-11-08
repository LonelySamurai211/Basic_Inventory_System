import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/auth_repository.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_controller.dart';

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AppUser>>(
      AdminUsersNotifier.new,
    );

class AdminUsersNotifier extends AsyncNotifier<List<AppUser>> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<List<AppUser>> build() => _repository.listUsers();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.listUsers());
  }

  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    String role = 'staff',
    String? position,
    int? age,
    Uint8List? avatarBytes,
    String? avatarExtension,
  }) async {
    final existing = await _repository.emailExists(email);
    if (existing != null) {
      return 'Email already registered.';
    }
    final created = await _repository.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      position: position,
      age: age,
    );
    if (created == null) {
      return 'Unable to create user right now.';
    }
    if (avatarBytes != null && avatarExtension != null) {
      final avatarUrl = await _repository.uploadAvatar(
        userId: created.id,
        data: avatarBytes,
        fileExtension: avatarExtension,
      );
      if (avatarUrl != null) {
        await _repository.updateUser(created, avatarUrl: avatarUrl);
      }
    }
    await refresh();
    return null;
  }

  Future<String?> deleteUser(String id, {required String currentUserId}) async {
    if (id == currentUserId) {
      return 'You cannot delete the signed-in account.';
    }
    final success = await _repository.deleteUser(id);
    if (!success) {
      return 'Failed to delete user. Please try again.';
    }
    await refresh();
    return null;
  }

  Future<String?> changeRole({
    required AppUser user,
    required String role,
  }) async {
    if (user.role == role) return null;
    final updated = await _repository.updateUser(user, role: role);
    if (updated == null) {
      return 'Unable to update role.';
    }
    await refresh();
    return null;
  }

  Future<String?> updateAvatar({
    required AppUser user,
    required Uint8List data,
    required String fileExtension,
  }) async {
    final avatarUrl = await _repository.uploadAvatar(
      userId: user.id,
      data: data,
      fileExtension: fileExtension,
    );
    if (avatarUrl == null) {
      return 'Unable to upload profile photo. Please try again.';
    }
    final updated = await _repository.updateUser(user, avatarUrl: avatarUrl);
    if (updated == null) {
      return 'Uploaded, but failed to save profile photo.';
    }
    await refresh();
    return null;
  }
}
