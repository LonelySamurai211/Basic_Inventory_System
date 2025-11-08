import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  AppUser? get _currentUser => state.whenOrNull(data: (value) => value);

  @override
  Future<AppUser?> build() async {
    final cached = await _repository.getPersistedUser();
    if (cached == null) return null;
    final fresh = await _repository.fetchUserById(cached.id);
    if (fresh != null) {
      await _repository.persistUser(fresh);
      return fresh;
    }
    await _repository.persistUser(null);
    return null;
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final user = await _repository.login(email: email, password: password);
    if (user == null) {
      state = const AsyncValue.data(null);
      return false;
    }
    await _repository.persistUser(user);
    state = AsyncValue.data(user);
    return true;
  }

  Future<String?> emailExists(String email) {
    return _repository.emailExists(email);
  }

  Future<AppUser?> refreshCurrent() async {
    final current = _currentUser;
    if (current == null) return null;
    final fresh = await _repository.fetchUserById(current.id);
    if (fresh == null) return null;
    await _repository.persistUser(fresh);
    state = AsyncValue.data(fresh);
    return fresh;
  }

  Future<bool> updateProfile({
    String? fullName,
    int? age,
    String? position,
    String? avatarUrl,
  }) async {
    final current = _currentUser;
    if (current == null) return false;
    final updated = await _repository.updateUser(
      current,
      fullName: fullName,
      age: age,
      position: position,
      avatarUrl: avatarUrl,
    );
    if (updated == null) return false;
    await _repository.persistUser(updated);
    state = AsyncValue.data(updated);
    return true;
  }

  Future<AppUser?> register({
    required String fullName,
    required String email,
    required String password,
    String? position,
    int? age,
    String role = 'staff',
    bool autoLogin = true,
  }) async {
    state = const AsyncLoading();
    final user = await _repository.register(
      fullName: fullName,
      email: email,
      password: password,
      position: position,
      age: age,
      role: role,
    );
    if (user == null) {
      state = const AsyncValue.data(null);
      return null;
    }
    if (autoLogin) {
      await _repository.persistUser(user);
      state = AsyncValue.data(user);
    } else {
      state = AsyncValue.data(_currentUser);
    }
    return user;
  }

  Future<void> logout() async {
    await _repository.persistUser(null);
    state = const AsyncValue.data(null);
  }
}
