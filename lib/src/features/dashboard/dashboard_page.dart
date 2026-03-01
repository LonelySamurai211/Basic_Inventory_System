import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../inventory/items_provider.dart';
import '../notifications/notifications_list_provider.dart';
import '../suppliers/supplier_validators.dart';
import '../suppliers/suppliers_provider.dart';
import '../transactions/transactions_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, required this.onNavigateToTab});

  final void Function(int index) onNavigateToTab;

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
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      refreshItems(ref),
      refreshTransactions(ref),
      refreshSuppliers(ref),
      refreshNotifications(ref),
    ]);
  }

  void _navigateToInventory() {
    widget.onNavigateToTab(1); // Inventory tab index
  }

  void _navigateToSuppliers() {
    widget.onNavigateToTab(2); // Suppliers tab index
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(itemsListProvider);
    final suppliers = ref.watch(suppliersListProvider);
    final transactions = ref.watch(transactionsProvider);
    final notifications = ref.watch(notificationsListProvider);

    final unreadNotifications =
        notifications.where((note) => note['is_read'] != true).length;

    final recentTransactions = transactions.take(5).toList(growable: false);
    final latestNotifications = notifications.take(5).toList(growable: false);
    final activityEntries = _buildActivityEntries(
      notifications: notifications,
      transactions: transactions,
    ).take(8).toList(growable: false);

    Widget statCard(String label, String value, IconData icon,
        {Color? color}) {
      final accent = color ?? theme.colorScheme.primary;
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(label, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget wrapCards(List<Widget> children) {
      const spacing = 16.0;
      return LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth >= 1000 ? 320.0 : 260.0;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children
                .map(
                  (card) => SizedBox(
                    width: constraints.maxWidth <= targetWidth
                        ? constraints.maxWidth
                        : targetWidth,
                    child: card,
                  ),
                )
                .toList(),
          );
        },
      );
    }

    List<Widget> buildTransactionTiles() {
      return recentTransactions
          .map((tx) {
            final type = (tx['type']?.toString() ?? 'in').toLowerCase();
            final isOut = type == 'out';
            final itemName = tx['item']?['name']?.toString() ?? 'Unknown item';
            final qty = tx['quantity']?.toString() ?? '0';
            final timestamp =
                _parseDate(tx['transaction_date']) ?? _parseDate(tx['occurred_at']);
            final subtitle = timestamp != null
                ? '${DateFormat('MMM d, yyyy').format(timestamp)} • Qty $qty'
                : 'Qty $qty';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isOut ? Icons.upload_outlined : Icons.download_outlined,
                color: isOut ? Colors.redAccent : Colors.green,
              ),
              title: Text(itemName),
              subtitle: Text(subtitle),
            );
          })
          .toList(growable: false);
    }

    List<Widget> buildNotificationTiles() {
      return latestNotifications
          .map(
            (note) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                note['is_read'] == true
                    ? Icons.notifications_none
                    : Icons.notifications_active_outlined,
                color: note['is_read'] == true ? null : Colors.orangeAccent,
              ),
              title: Text(
                (note['title']?.toString().trim().isNotEmpty ?? false)
                    ? note['title'].toString()
                    : 'Notification',
              ),
              subtitle: Text(note['message']?.toString() ?? ''),
            ),
          )
          .toList(growable: false);
    }

    List<Widget> buildActivityTiles() {
      return activityEntries
          .map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(entry.icon, color: entry.iconColor),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              trailing: entry.timestamp == null
                  ? null
                  : Text(DateFormat('MMM d, HH:mm').format(entry.timestamp!)),
            ),
          )
          .toList(growable: false);
    }

    final stats = [
      statCard('Inventory items', items.length.toString(),
          Icons.inventory_2_outlined),
        statCard(
        'Suppliers on file',
        suppliers.length.toString(),
        Icons.store_mall_directory_outlined,
      ),
      statCard(
        'Unread notifications',
        unreadNotifications.toString(),
        Icons.notifications_active_outlined,
        color: Colors.orange,
      ),
    ];

    final quickActions = [
      _QuickActionButton(
        icon: Icons.inventory_2_outlined,
        title: 'Check inventory item list',
        description: 'Navigate to the Inventory page to manage items.',
        onPressed: _navigateToInventory,
      ),
      _QuickActionButton(
        icon: Icons.storefront_outlined,
        title: 'Check supplier list',
        description: 'Navigate to the Suppliers page to manage suppliers.',
        onPressed: _navigateToSuppliers,
      ),
       _QuickActionButton(
        icon: Icons.storefront_outlined,
        title: 'Check reports list',
        description: 'Navigate to the Reports page to view list or reports',
        onPressed: _navigateToSuppliers,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overview',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshAll,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          wrapCards(stats),
          const SizedBox(height: 32),
          Text('Quick actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          wrapCards(quickActions),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity timeline',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (activityEntries.isEmpty)
                    Text(
                      'No activity recorded yet. Actions from any tab will show up here.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    ...buildActivityTiles(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          wrapCards([
            _RecentListCard(
              title: 'Recent transactions',
              emptyText: 'Log a transaction to populate this list.',
              children: buildTransactionTiles(),
            ),
            _RecentListCard(
              title: 'Notifications',
              emptyText: 'No notifications yet.',
              children: buildNotificationTiles(),
            ),
          ]),
        ],
      ),
    );
  }

  List<_ActivityEntry> _buildActivityEntries({
    required List<Map<String, dynamic>> notifications,
    required List<Map<String, dynamic>> transactions,
  }) {
    final entries = <_ActivityEntry>[];

    for (final note in notifications) {
      final title = (note['title']?.toString().trim().isNotEmpty ?? false)
          ? note['title'].toString()
          : 'Notification';
      final subtitle = note['message']?.toString().trim() ?? '';
      final timestamp =
          _parseDate(note['created_at']) ?? _parseDate(note['inserted_at']);
      entries.add(
        _ActivityEntry(
          icon: note['is_read'] == true
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
          iconColor: note['is_read'] == true ? null : Colors.orangeAccent,
          title: title,
          subtitle: subtitle,
          timestamp: timestamp,
        ),
      );
    }

    for (final tx in transactions) {
      final type = tx['type']?.toString() ?? 'in';
      final isStockOut = type == 'out';
      final itemName = tx['item']?['name']?.toString() ?? 'Unknown item';
      final title = '${isStockOut ? 'Stock out' : 'Stock in'} • $itemName';
      final qty = tx['quantity']?.toString() ?? '0';
      final timestamp =
          _parseDate(tx['transaction_date']) ?? _parseDate(tx['occurred_at']);
      entries.add(
        _ActivityEntry(
          icon: isStockOut ? Icons.upload_outlined : Icons.download_outlined,
          iconColor: isStockOut ? Colors.redAccent : Colors.green,
          title: title,
          subtitle: 'Qty $qty',
          timestamp: timestamp,
        ),
      );
    }

    entries.sort((a, b) {
      final aTs = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTs = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTs.compareTo(aTs);
    });
    return entries;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

}

class _ActivityEntry {
  const _ActivityEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.timestamp,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final Color? iconColor;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
    this.enabled = true,
    this.disabledReason,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final String? disabledReason;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final cardColor = baseColor.withValues(alpha: enabled ? 0.9 : 0.75);
    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall,
            ),
            if (!enabled && disabledReason != null) ...[
              const SizedBox(height: 8),
              Text(
                disabledReason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: enabled ? () => onPressed() : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSupplierDialog extends ConsumerStatefulWidget {
  const _AddSupplierDialog();

  @override
  ConsumerState<_AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<_AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await createSupplierAndRefresh(
      ref,
      name: _nameController.text.trim(),
      taxId: _taxIdController.text.trim(),
      contactNumber: _phoneController.text.trim(),
      contactEmail: _emailController.text.trim().toLowerCase(),
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the supplier.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add supplier'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Supplier name'),
                inputFormatters: [SupplierInputFormatters.lettersOnly],
                validator: SupplierValidators.name,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: 'Tax identification number',
                  hintText: '111-222-333-444',
                ),
                inputFormatters: [SupplierInputFormatters.taxId],
                validator: SupplierValidators.taxId,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: SupplierValidators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact number',
                  helperText: '11-digit mobile or 7-digit telephone',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [SupplierInputFormatters.digitsOnly],
                validator: SupplierValidators.contactNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Company address'),
                minLines: 2,
                maxLines: 3,
                validator: SupplierValidators.address,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save supplier'),
        ),
      ],
    );
  }
}

class _RecentListCard extends StatelessWidget {
  const _RecentListCard({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Text(emptyText, style: theme.textTheme.bodyMedium)
            else
              ...children,
          ],
        ),
      ),
    );
  }
}
