  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'data/notifications_repository.dart';

  /// Provider exposing the list of notifications.
  final notificationsListProvider =
      NotifierProvider<NotificationsListNotifier, List<Map<String, dynamic>>>(
    NotificationsListNotifier.new,
  );

  /// Notifier responsible for keeping notifications synced with Supabase.
  class NotificationsListNotifier extends Notifier<List<Map<String, dynamic>>> {
    @override
    List<Map<String, dynamic>> build() => [];

    /// Load all notifications from Supabase.
    Future<void> load() async {
      final items = await NotificationsRepository.fetchNotifications();
      state = items;
    }

    /// Reload from Supabase.
    Future<void> refresh() => load();

    /// Insert or update a notification in the in-memory list.
    void upsert(Map<String, dynamic> notification) {
      final id = notification['id'];
      if (id == null) {
        state = [notification, ...state];
        return;
      }

      final index = state.indexWhere((n) => n['id'] == id);
      if (index == -1) {
        state = [notification, ...state];
      } else {
        final updated = [...state];
        updated[index] = notification;
        state = updated;
      }
    }

    /// Delete a notification by ID.
    Future<bool> delete(String id) async {
      final success = await NotificationsRepository.deleteNotification(id);
      if (success) {
        state = state.where((n) => n['id'].toString() != id).toList();
      }
      return success;
    }

    /// Clear all notifications from DB.
    Future<bool> clearAll() async {
      final ids = state.map((n) => n['id'].toString()).toList();
      bool allSuccess = true;

      for (final id in ids) {
        final success = await NotificationsRepository.deleteNotification(id);
        if (!success) allSuccess = false;
      }

      await load();
      return allSuccess;
    }
  }

  Future<void> refreshNotifications(WidgetRef ref) async {
    final notifier = ref.read(notificationsListProvider.notifier);
    await notifier.load();
  }
