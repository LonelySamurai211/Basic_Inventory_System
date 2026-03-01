import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory/inventory_transactions_page.dart';
import '../dashboard/dashboard_page.dart';
import '../notifications/data/notifications_repository.dart';
import '../notifications/notifications_list_provider.dart';
import '../notifications/widgets/notification_popup.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../suppliers/suppliers_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  int _previousUnreadCount = 0;
  Map<String, dynamic>? _currentPopupNotification;
  bool _showPopup = false;



  @override
  Widget build(BuildContext context) {
    final destinations = _buildDestinations();

    final clampedIndex = _selectedIndex.clamp(0, destinations.length - 1);
    if (clampedIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = clampedIndex);
      });
    }

    final currentIndex = clampedIndex;
    final notifications = ref.watch(notificationsListProvider);
    final unreadNotifications =
        notifications.where((n) => n['is_read'] != true).length;

    // Initialize previous count on first build
// Only update previous count after checking new notifications
final isNewNotification = unreadNotifications > _previousUnreadCount;

if (isNewNotification && !_showPopup) {
  final newNotifications = notifications.where((n) => n['is_read'] != true).toList();
  if (newNotifications.isNotEmpty) {
    _currentPopupNotification = newNotifications.first;
    _showPopup = true;
  }
}

_previousUnreadCount = unreadNotifications;


    // Check for new notifications
    if (unreadNotifications > _previousUnreadCount && !_showPopup) {
      final newNotifications = notifications.where((n) => n['is_read'] != true).toList();
      if (newNotifications.isNotEmpty) {
        _currentPopupNotification = newNotifications.first;
        _showPopup = true;
      }
    }
    _previousUnreadCount = unreadNotifications;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1000;

        return SizedBox.expand(
          child: Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: Text(destinations[currentIndex].label),
                  actions: [
                    IconButton(
                      tooltip: 'View notifications',
                      onPressed: () => _openNotificationsDialog(context, ref),
                      icon: Badge.count(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        count: unreadNotifications,
                        child: const Icon(Icons.notifications_outlined),
                      ),
                    ),
                  ],
                ),
                drawer: isCompact ? _buildDrawer(destinations, currentIndex) : null,
                body: Row(
                  children: [
                    if (!isCompact) _buildRail(destinations, currentIndex),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey(destinations[currentIndex].id),
                          child: destinations[currentIndex].builder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showPopup && _currentPopupNotification != null)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: NotificationPopup(
                    notification: _currentPopupNotification!,
                    onDismiss: () {
                      setState(() {
                        _showPopup = false;
                        _currentPopupNotification = null;
                      });
                    },
                    onTap: () {
                      setState(() {
                        _showPopup = false;
                      });
                      _openNotificationsDialog(context, ref);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail(List<_Destination> destinations, int currentIndex) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      minExtendedWidth: 220,
      extended: true,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }

  Widget _buildDrawer(List<_Destination> destinations, int currentIndex) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Inventory System',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final isSelected = index == currentIndex;
                  final theme = Theme.of(context);
                  return ListTile(
                    leading: Icon(
                      destination.icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    title: Text(destination.label),
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotificationsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Mark all notifications as read when opening the dialog
    await NotificationsRepository.markAllAsRead();
    await ref.read(notificationsListProvider.notifier).refresh();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final notifications = ref.watch(notificationsListProvider);
          final entries = notifications.take(20).toList(growable: false);
          final theme = Theme.of(dialogContext);

          final content = entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No notifications yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (_, index) {
                    final note = entries[index];
                    final isUnread = note['is_read'] != true;
                    final title =
                        (note['title']?.toString().trim().isNotEmpty ?? false)
                            ? note['title'].toString()
                            : 'Notification';
                    final subtitle =
                        (note['message'] ?? note['description'] ?? '').toString();

                    final timestamp =
                        note['created_at'] ?? note['inserted_at'];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isUnread
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none,
                        color: isUnread ? Colors.orangeAccent : null,
                      ),
                      title: Text(title),
                      subtitle: Text(subtitle),
                      trailing: timestamp != null
                          ? Text(
                              _formatTimestamp(dialogContext, timestamp),
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                    );
                  },
                );

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 360, maxHeight: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Notifications',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete all notifications',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: dialogContext,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete All Notifications'),
                                content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete All'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(notificationsListProvider.notifier).clearAll();
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(BuildContext context, dynamic value) {
    DateTime? timestamp;

    if (value is DateTime) {
      timestamp = value;
    } else if (value is String && value.isNotEmpty) {
      timestamp = DateTime.tryParse(value);
    }

    if (timestamp == null) return '';

    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatShortDate(timestamp);
    final timeLabel =
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp));
    return '$dateLabel • $timeLabel';
  }

  void _navigateToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  List<_Destination> _buildDestinations() {
    return [
      _Destination(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: () => DashboardPage(onNavigateToTab: _navigateToTab),
      ),
      _Destination(
        id: 'inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        builder: () => const InventoryTransactionsPage(),
      ),
      _Destination(
        id: 'suppliers',
        label: 'Suppliers',
        icon: Icons.storefront_outlined,
        builder: () => const SuppliersPage(),
      ),
      _Destination(
        id: 'reports',
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        builder: () => const ReportsPage(),
      ),
      _Destination(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: () => const SettingsPage(),
      ),
    ];
  }
}

class _Destination {
  const _Destination({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final IconData icon;
  final Widget Function() builder;
}
