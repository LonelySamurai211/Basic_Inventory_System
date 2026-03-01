import 'package:supabase_flutter/supabase_flutter.dart';
class NotificationsRepository {
  const NotificationsRepository._();

  static final _client = Supabase.instance.client;

  /// Fetch all notifications from Supabase
  static Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final res = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);

    return res.map<Map<String, dynamic>>((n) => n as Map<String, dynamic>).toList();
  }

  /// Insert a single notification
  static Future<Map<String, dynamic>?> insertNotification(
      Map<String, dynamic> data) async {
    final res = await _client
        .from('notifications')
        .insert(data)
        .select()
        .single();

    return res;
  }

  /// Mark a notification as read
  static Future<Map<String, dynamic>?> markAsRead(String id, bool isRead) async {
    final res = await _client
        .from('notifications')
        .update({'is_read': isRead})
        .eq('id', id)
        .select()
        .maybeSingle();

    return res;
  }

  /// Mark ALL notifications as read
  static Future<bool> markAllAsRead() async {
    await _client.from('notifications').update({'is_read': true}).eq('is_read', false);
    return true;
  }

  /// Delete a single notification
  static Future<bool> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
    return true;
  }
}
