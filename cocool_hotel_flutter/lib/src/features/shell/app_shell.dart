import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../dashboard/dashboard_page.dart';
import '../inventory/inventory_page.dart';
import '../notifications/notifications_page.dart';
import '../purchase_orders/purchase_orders_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../suppliers/suppliers_page.dart';
import '../transactions/transactions_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<_Destination> _destinations;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _destinations = [
      _Destination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        builder: () => const DashboardPage(),
      ),
      _Destination(
        label: 'Inventory',
        icon: Icons.inventory_2_outlined,
        builder: () => const InventoryPage(),
      ),
      _Destination(
        label: 'Transactions',
        icon: Icons.compare_arrows_outlined,
        builder: () => const TransactionsPage(),
      ),
      _Destination(
        label: 'Purchase Orders',
        icon: Icons.receipt_long_outlined,
        builder: () => const PurchaseOrdersPage(),
      ),
      _Destination(
        label: 'Suppliers',
        icon: Icons.storefront_outlined,
        builder: () => const SuppliersPage(),
      ),
      _Destination(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        builder: () => const ReportsPage(),
      ),
      _Destination(
        label: 'Notifications',
        icon: Icons.notifications_outlined,
        builder: () => const NotificationsPage(),
      ),
      _Destination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        builder: () => const SettingsPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(_destinations[_selectedIndex].label),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.forest,
                child: const Text('HK'),
              ),
              const SizedBox(width: 24),
            ],
          ),
          drawer: isCompact ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isCompact) _buildRail(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_destinations[_selectedIndex].label),
                    child: _destinations[_selectedIndex].builder(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      minExtendedWidth: 220,
      extended: true,
      destinations: _destinations
          .map(
            (dest) => NavigationRailDestination(
              icon: Icon(dest.icon),
              label: Text(dest.label),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Navigation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final destination = _destinations[index];
                  final isSelected = index == _selectedIndex;
                  return ListTile(
                    leading: Icon(destination.icon,
                        color: isSelected
                            ? AppColors.forest
                            : AppColors.graphite),
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
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Widget Function() builder;
}
