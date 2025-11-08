import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/app_user.dart';
import '../inventory/items_provider.dart';
import '../notifications/data/notifications_repository.dart';
import '../suppliers/suppliers_provider.dart';
import '../transactions/transactions_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.user});

  final AppUser? user;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    refreshItems(ref);
    refreshTransactions(ref);
    refreshSuppliers(ref);
    refreshNotifications(ref, recipientId: widget.user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsListProvider);
    final suppliers = ref.watch(suppliersListProvider);
    final transactions = ref.watch(transactionsProvider);
  final notifications = ref.watch(notificationsListProvider);
  final filteredNotifications = widget.user == null
    ? notifications
    : notifications
      .where((note) =>
        note['recipient_id'] == null ||
        note['recipient_id']?.toString() == widget.user!.id)
      .toList();

    final lowStock = items.where((item) {
      final stock = int.tryParse(item['stock_qty']?.toString() ?? '') ?? 0;
      final reorder = int.tryParse(item['reorder_level']?.toString() ?? '') ?? 0;
      return reorder > 0 && stock <= reorder;
    }).toList();

    final latestTransactions = transactions.take(5).toList();
    final latestNotifications = filteredNotifications.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hotel operations at a glance',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _SummaryGrid(
            tiles: [
              _SummaryTile(
                label: 'Inventory items',
                value: items.length.toString(),
                icon: Icons.inventory_2_outlined,
              ),
              _SummaryTile(
                label: 'Low stock alerts',
                value: lowStock.length.toString(),
                icon: Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
              _SummaryTile(
                label: 'Supplier partners',
                value: suppliers.length.toString(),
                icon: Icons.storefront_outlined,
              ),
              _SummaryTile(
                label: 'Transactions (30 days)',
                value: _countRecentTransactions(transactions).toString(),
                icon: Icons.swap_vert_circle_outlined,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SectionCard(
            title: 'Low stock watchlist',
            emptyText: 'All stock levels look healthy right now.',
            isEmpty: lowStock.isEmpty,
            child: _LowStockList(items: lowStock),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SectionCard(
                  title: 'Recent transactions',
                  emptyText: 'Log a transaction to see it here.',
                  isEmpty: latestTransactions.isEmpty,
                  child: _RecentTransactionsList(items: latestTransactions),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _SectionCard(
                  title: 'Latest notifications',
                  emptyText: 'No updates yet. You\'re all caught up!',
                  isEmpty: latestNotifications.isEmpty,
                  child: _RecentNotificationsList(items: latestNotifications),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countRecentTransactions(List<Map<String, dynamic>> transactions) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return transactions.where((tx) {
      final dt = DateTime.tryParse(tx['occurred_at']?.toString() ?? '');
      if (dt == null) return false;
      return dt.isAfter(thirtyDaysAgo);
    }).length;
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.tiles});

  final List<_SummaryTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tileWidth = 220.0;
        const spacing = 16.0;
        final columns = constraints.maxWidth <= tileWidth
            ? 1
            : (constraints.maxWidth / tileWidth).floor().clamp(1, 4);
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: width,
                  child: tile,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = color ?? colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.emptyText,
    required this.child,
    this.isEmpty = false,
  });

  final String title;
  final String emptyText;
  final Widget child;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            child,
            if (isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                emptyText,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyPlaceholder();
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item['name']?.toString() ?? ''),
            subtitle: Text(
              'Qty: ${item['stock_qty']} • Reorder at ${item['reorder_level']}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
      ],
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyPlaceholder();
    }
    return Column(
      children: [
        for (final tx in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.compare_arrows,
              color: tx['type'] == 'out'
                  ? Colors.redAccent
                  : tx['type'] == 'in'
                      ? Colors.green
                      : Colors.blueGrey,
            ),
            title: Text(tx['item']?['name']?.toString() ?? 'Unknown item'),
            subtitle: Text(
              '${tx['type']} • Qty ${tx['quantity']} • ${tx['occurred_at']}',
            ),
          ),
      ],
    );
  }
}

class _RecentNotificationsList extends StatelessWidget {
  const _RecentNotificationsList({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyPlaceholder();
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final note in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              note['is_read'] == true
                  ? Icons.notifications_none
                  : Icons.notifications_active_outlined,
            ),
            title: Text(note['title']?.toString() ?? ''),
            subtitle: Text(
              note['message']?.toString() ?? '',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      ),
      child: Center(
        child: Text(
          'No records yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
