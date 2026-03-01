import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../inventory/items_provider.dart';
import '../notifications/notifications_list_provider.dart'; 
import '../suppliers/suppliers_provider.dart';
import '../transactions/transactions_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _refreshing = false;

  Future<void> _refreshWorkspace() async {
    setState(() => _refreshing = true);
    await Future.wait([
      refreshItems(ref),
      refreshSuppliers(ref),
      refreshTransactions(ref),
      refreshNotifications(ref),
    ]);
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workspace data refreshed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      children: [
        Text(
          'Workspace Settings',
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          'Control data refreshes and review system integrations in one place.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data maintenance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  'Run a full refresh to pull the latest inventory, supplier, transaction, notification, and report data.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _refreshing ? null : _refreshWorkspace,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_outlined),
                    label: const Text('Refresh workspace data'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Integrations', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  'This workspace connects directly to Supabase for realtime data. Future updates will surface additional integration controls here.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Integration management coming soon.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.extension_outlined),
                  label: const Text('Manage integrations'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
