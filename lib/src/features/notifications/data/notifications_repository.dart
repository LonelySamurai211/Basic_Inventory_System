import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsNotifier
    extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setItems(List<Map<String, dynamic>> items) => state = items;

  void upsert(Map<String, dynamic> item) {
    final list = [...state];
    final index = list.indexWhere((element) => element['id'] == item['id']);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.insert(0, item);
    }
    list.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    state = list;
  }
}

final notificationsListProvider =
    NotifierProvider<NotificationsNotifier, List<Map<String, dynamic>>>(
      NotificationsNotifier.new,
    );

class NotificationsRepository {
  NotificationsRepository._();

  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchNotifications({
    String? recipientId,
  }) async {
    try {
      final base = _client.from('notifications').select();
      final filtered = recipientId != null
          ? base.eq('recipient_id', recipientId)
          : base;
      final res = await filtered.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createNotification({
    required String title,
    required String message,
    String? category,
    String? recipientId,
  }) async {
    try {
      final insert = await _client
          .from('notifications')
          .insert({
            'title': title,
            'message': message,
            'category': category,
            'recipient_id': recipientId,
          })
          .select()
          .maybeSingle();
      if (insert == null) return null;
      return Map<String, dynamic>.from(insert as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> markAsRead(String id, bool value) async {
    try {
      final updated = await _client
          .from('notifications')
          .update({'is_read': value})
          .eq('id', id)
          .select()
          .maybeSingle();
      if (updated == null) return null;
      return Map<String, dynamic>.from(updated as Map);
    } catch (_) {
      return null;
    }
  }
}

Future<void> refreshNotifications(WidgetRef ref, {String? recipientId}) async {
  final list = await NotificationsRepository.fetchNotifications(
    recipientId: recipientId,
  );
  ref.read(notificationsListProvider.notifier).setItems(list);
}
