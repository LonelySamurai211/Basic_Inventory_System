import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_users_page.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/auth_controller.dart';
import '../dashboard/dashboard_page.dart';
import '../inventory/inventory_page.dart';
import '../notifications/data/notifications_repository.dart';
import '../notifications/notifications_page.dart';
import '../purchase_orders/purchase_orders_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../suppliers/suppliers_page.dart';
import '../transactions/transactions_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final destinations = _buildDestinations(widget.user);
    if (_selectedIndex >= destinations.length) {
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _buildDestinations(widget.user);
    final unreadNotifications = ref
        .watch(notificationsListProvider)
        .where(
          (note) =>
              (note['recipient_id'] == null ||
                  note['recipient_id']?.toString() == widget.user.id) &&
              note['is_read'] != true,
        )
        .length;

    final notificationsIndex = destinations.indexWhere(
      (element) => element.id == 'notifications',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1000;
        return Scaffold(
          appBar: AppBar(
            title: Text(destinations[_selectedIndex].label),
            actions: [
              if (notificationsIndex != -1)
                IconButton(
                  onPressed: () {
                    setState(() => _selectedIndex = notificationsIndex);
                  },
                  icon: Badge.count(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    count: unreadNotifications,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  tooltip: 'View notifications',
                ),
              _ProfileMenu(user: widget.user),
            ],
          ),
          drawer: isCompact ? _buildDrawer(destinations) : null,
          body: Row(
            children: [
              if (!isCompact) _buildRail(destinations),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(destinations[_selectedIndex].id),
                    child: destinations[_selectedIndex].builder(
                      ref,
                      widget.user,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail(List<_Destination> destinations) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
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

  Widget _buildDrawer(List<_Destination> destinations) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Cocool Hotel',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final isSelected = index == _selectedIndex;
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

  List<_Destination> _buildDestinations(AppUser user) {
    final list = <_Destination>[
      _Destination(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: (ref, user) => DashboardPage(user: user),
      ),
      _Destination(
        id: 'inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        builder: (_, __) => const InventoryPage(),
      ),
      _Destination(
        id: 'transactions',
        label: 'Transactions',
        icon: Icons.compare_arrows_outlined,
        builder: (_, __) => const TransactionsPage(),
      ),
      _Destination(
        id: 'purchase-orders',
        label: 'Purchase Orders',
        icon: Icons.receipt_long_outlined,
        builder: (_, __) => const PurchaseOrdersPage(),
      ),
      _Destination(
        id: 'suppliers',
        label: 'Suppliers',
        icon: Icons.storefront_outlined,
        builder: (_, __) => const SuppliersPage(),
      ),
      _Destination(
        id: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        builder: (ref, user) => NotificationsPage(user: user),
      ),
      _Destination(
        id: 'reports',
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        builder: (_, user) => ReportsPage(user: user),
      ),
      _Destination(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: (ref, user) => SettingsPage(user: user),
      ),
    ];

    if (user.isAdmin) {
      list.add(
        _Destination(
          id: 'admin',
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          builder: (_, user) => AdminUsersPage(currentUser: user),
        ),
      );
    }

    return list;
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
  final Widget Function(WidgetRef ref, AppUser user) builder;
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = user.fullName.isNotEmpty
        ? _initialsFromText(user.fullName)
        : _initialsFromText(user.email);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<_ProfileAction>(
        tooltip: 'Account',
        position: PopupMenuPosition.under,
        onSelected: (action) async {
          switch (action) {
            case _ProfileAction.logout:
              await ref.read(authControllerProvider.notifier).logout();
              break;
            case _ProfileAction.profile:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile management coming soon.'),
                ),
              );
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _ProfileAction.profile,
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.fullName),
              subtitle: Text(user.role.toUpperCase()),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ProfileAction.logout,
            child: ListTile(
              leading: Icon(Icons.logout_outlined),
              title: Text('Sign out'),
            ),
          ),
        ],
        child: CircleAvatar(radius: 18, child: Text(initials)),
      ),
    );
  }
}

enum _ProfileAction { profile, logout }

String _initialsFromText(String text) {
  final parts = text.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final buffer = StringBuffer();
  for (final part in parts) {
    if (buffer.length >= 2) break;
    final iterator = part.runes.iterator;
    if (iterator.moveNext()) {
      buffer.write(String.fromCharCode(iterator.current).toUpperCase());
    }
  }
  if (buffer.isEmpty) {
    final iterator = text.runes.iterator;
    if (iterator.moveNext()) {
      return String.fromCharCode(iterator.current).toUpperCase();
    }
    return '?';
  }
  return buffer.toString();
}
