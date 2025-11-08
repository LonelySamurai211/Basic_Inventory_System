import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/app_user.dart';
import 'data/notifications_repository.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _refresh();
  }

  Future<void> _refresh() {
    return refreshNotifications(ref, recipientId: widget.user.id);
  }

  Future<void> _toggleRead(Map<String, dynamic> notification) async {
    final updated = await NotificationsRepository.markAsRead(
      notification['id'].toString(),
      notification['is_read'] != true,
    );
    if (updated == null) return;
    ref.read(notificationsListProvider.notifier).upsert(updated);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsListProvider);
    final filtered = notifications
        .where((note) => note['recipient_id'] == null ||
            note['recipient_id']?.toString() == widget.user.id)
        .toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        children: [
          Text(
            'Alerts & Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Stay ahead of low stock, expiries, and approvals in one glance.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (filtered.isEmpty)
            _EmptyNotifications(onRefresh: _refresh)
          else
            ...filtered.map((item) => _NotificationTile(
                  data: item,
                  onToggleRead: () => _toggleRead(item),
                )),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.data, required this.onToggleRead});

  final Map<String, dynamic> data;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = DateTime.tryParse(data['created_at']?.toString() ?? '');
    final isRead = data['is_read'] == true;
    final title = data['title']?.toString() ?? 'Notification';
    final message = data['message']?.toString() ?? '';
    final category = data['category']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          isRead ? Icons.notifications_none : Icons.notifications_active,
          color: isRead ? theme.colorScheme.outline : theme.colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (category != null && category.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                if (category != null && category.isNotEmpty)
                  const SizedBox(width: 12),
                Text(
                  createdAt != null
                      ? MaterialLocalizations.of(context).formatShortDate(createdAt)
                      : 'Unknown date',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: onToggleRead,
          icon: Icon(isRead ? Icons.mark_email_unread : Icons.mark_email_read),
          tooltip: isRead ? 'Mark as unread' : 'Mark as read',
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.celebration_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'All clear for now',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Alerts will appear here and on the dashboard when triggered.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Refresh now'),
            ),
          ],
        ),
      ),
    );
  }
}
