import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';
import 'suppliers_provider.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      // Load suppliers the first time the page is shown.
      refreshSuppliers(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Supplier Directory',
            subtitle:
                'Track vendors and keep contact information within reach.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () {
                _showCreateDialog();
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add supplier'),
            ),
          ),
          const SizedBox(height: 24),
          if (suppliers.isEmpty)
            EmptyPlaceholder(
              title: 'No suppliers yet',
              message: 'Log each vendor so your team knows who to contact.',
              icon: Icons.store_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 320.0;
                const spacing = 16.0;
                final maxWidth = constraints.maxWidth;
                final computedColumns = maxWidth <= minCardWidth
                    ? 1
                    : (maxWidth / minCardWidth).floor();
                final columns = computedColumns < 1
                    ? 1
                    : (computedColumns > 4 ? 4 : computedColumns);
                final cardWidth = columns == 1
                    ? maxWidth
                    : (maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final supplier in suppliers)
                      SizedBox(
                        width: cardWidth,
                        child: _SupplierCard(
                          supplier: supplier,
                          onEdit: () {
                            _showEditDialog(supplier);
                          },
                          onDelete: () {
                            _deleteSupplier(supplier['id'] as String);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SuppliersRepository.deleteSupplier(id);
    if (!mounted) return;

    if (ok) {
      await refreshSuppliers(ref);
      messenger.showSnackBar(const SnackBar(content: Text('Supplier deleted')));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete supplier')),
      );
    }
  }

  void _showCreateDialog() {
    final nameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final addrCtl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Contact email'),
            ),
            TextField(
              controller: addrCtl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtl.text.trim();
              if (name.isEmpty) return;
              final contact = {'email': emailCtl.text.trim()};
              final ok = await createSupplierAndRefresh(
                ref,
                name: name,
                address: addrCtl.text.trim(),
                contact: contact,
              );
              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Supplier created' : 'Failed to create supplier',
                  ),
                ),
              );
              if (ok && navigator.canPop()) {
                navigator.pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> supplier) {
    final nameCtl = TextEditingController(
      text: supplier['name']?.toString() ?? '',
    );
    final emailCtl = TextEditingController(
      text: supplier['contact']?['email']?.toString() ?? '',
    );
    final addrCtl = TextEditingController(
      text: supplier['address']?.toString() ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(labelText: 'Contact email'),
            ),
            TextField(
              controller: addrCtl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtl.text.trim();
              if (name.isEmpty) return;
              final contact = {'email': emailCtl.text.trim()};
              final updated = await SuppliersRepository.updateSupplier(
                id: supplier['id'] as String,
                name: name,
                address: addrCtl.text.trim(),
                contact: contact,
              );
              if (!mounted) return;

              if (updated != null) {
                await refreshSuppliers(ref);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Supplier updated')),
                );
                if (navigator.canPop()) {
                  navigator.pop();
                }
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to update supplier')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final contact = supplier['contact'];
    final contactEmail = contact is Map
        ? contact['email']?.toString() ?? ''
        : '';
    final phone = contact is Map ? contact['phone']?.toString() ?? '' : '';
    final address = supplier['address']?.toString() ?? '';
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    supplier['name']?.toString() ?? 'Unnamed supplier',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (contactEmail.isNotEmpty)
                  _SupplierInfoPill(
                    icon: Icons.mail_outline,
                    label: contactEmail,
                  ),
                _SupplierInfoPill(
                  icon: Icons.phone_enabled_outlined,
                  label: phone.isEmpty ? 'No phone' : phone,
                ),
                _SupplierInfoPill(
                  icon: Icons.location_on_outlined,
                  label: address.isEmpty ? 'No address provided' : address,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierInfoPill extends StatelessWidget {
  const _SupplierInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
