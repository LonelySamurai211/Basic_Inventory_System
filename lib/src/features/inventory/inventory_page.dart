import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/section_header.dart';
import '../../widgets/empty_placeholder.dart';
import '../suppliers/suppliers_provider.dart';
import 'items_provider.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      // Load items once when page first appears.
      refreshItems(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsListProvider);
    final suppliers = ref.watch(suppliersListProvider);
    final supplierLookup = {
      for (final sup in suppliers)
        if (sup['id'] != null)
          sup['id'] as String: sup['name']?.toString() ?? '',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Inventory Catalog',
            subtitle: 'Maintain stock levels and supplier assignments.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () {
                _showAddItemDialog();
              },
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Add item'),
            ),
          ),
          const SizedBox(height: 24),
          if (items.isEmpty)
            EmptyPlaceholder(
              title: 'No items yet',
              message:
                  'Start by adding materials or importing your existing catalog.',
              icon: Icons.inventory_2_outlined,
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
                    for (final it in items)
                      SizedBox(
                        width: cardWidth,
                        child: _InventoryCard(
                          item: it,
                          supplierName:
                              supplierLookup[it['supplier_id']] ?? 'Unassigned',
                          onEdit: () {
                            _showEditItemDialog(it);
                          },
                          onDelete: () {
                            _deleteItem(it['id'] as String);
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

  Future<void> _deleteItem(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await deleteItemFromProvider(ref, id);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'Item deleted' : 'Failed to delete item')),
    );
  }

  Future<void> _showAddItemDialog() async {
    if (ref.read(suppliersListProvider).isEmpty) {
      await refreshSuppliers(ref);
      if (!mounted) return;
    }
    final suppliers = ref.read(suppliersListProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nameCtl = TextEditingController();
    final unitCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '0');
    final reorderCtl = TextEditingController(text: '0');
    String? selectedSupplier;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: unitCtl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: qtyCtl,
                decoration: const InputDecoration(labelText: 'Initial qty'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: reorderCtl,
                decoration: const InputDecoration(labelText: 'Reorder level'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              if (suppliers.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...suppliers.map(
                      (s) => DropdownMenuItem(
                        value: s['id']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedSupplier = value),
                )
              else
                const Text('Add suppliers to assign one here.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                if (name.isEmpty) return;
                final unit = unitCtl.text.trim().isEmpty
                    ? null
                    : unitCtl.text.trim();
                final qty = int.tryParse(qtyCtl.text) ?? 0;
                final reorder = int.tryParse(reorderCtl.text) ?? 0;

                final success = await createItem(
                  ref,
                  name: name,
                  unit: unit,
                  stock: qty,
                  reorder: reorder,
                  supplierId: selectedSupplier,
                );
                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Item created' : 'Failed to create item',
                    ),
                  ),
                );
                if (success && navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditItemDialog(Map<String, dynamic> it) async {
    if (ref.read(suppliersListProvider).isEmpty) {
      await refreshSuppliers(ref);
      if (!mounted) return;
    }
    final suppliers = ref.read(suppliersListProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final nameCtl = TextEditingController(text: it['name']?.toString() ?? '');
    final unitCtl = TextEditingController(text: it['unit']?.toString() ?? '');
    final qtyCtl = TextEditingController(
      text: (it['stock_qty'] ?? 0).toString(),
    );
    final reorderCtl = TextEditingController(
      text: (it['reorder_level'] ?? 0).toString(),
    );
    String? selectedSupplier = it['supplier_id']?.toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: unitCtl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: qtyCtl,
                decoration: const InputDecoration(labelText: 'Qty'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: reorderCtl,
                decoration: const InputDecoration(labelText: 'Reorder level'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              if (suppliers.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: selectedSupplier?.isEmpty == true
                      ? null
                      : selectedSupplier,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...suppliers.map(
                      (s) => DropdownMenuItem(
                        value: s['id']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedSupplier = value),
                )
              else
                const Text('Add suppliers to assign one here.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtl.text.trim();
                if (name.isEmpty) return;
                final unit = unitCtl.text.trim().isEmpty
                    ? null
                    : unitCtl.text.trim();
                final qty = int.tryParse(qtyCtl.text);
                final reorder = int.tryParse(reorderCtl.text);

                final success = await updateItemInProvider(
                  ref,
                  id: it['id'] as String,
                  name: name,
                  unit: unit,
                  stock: qty,
                  reorder: reorder,
                  supplierId: selectedSupplier,
                );
                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Item updated' : 'Failed to update item',
                    ),
                  ),
                );
                if (success && navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.supplierName,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final String supplierName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = int.tryParse(item['stock_qty']?.toString() ?? '') ?? 0;
    final reorder = int.tryParse(item['reorder_level']?.toString() ?? '') ?? 0;
    final unit = item['unit']?.toString().isNotEmpty == true
        ? item['unit'].toString()
        : '-';

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? '<unnamed>',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supplierName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                _InfoPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'Qty: $qty',
                  background: theme.colorScheme.primaryContainer,
                  foreground: theme.colorScheme.onPrimaryContainer,
                ),
                _InfoPill(icon: Icons.straighten, label: 'Unit: $unit'),
                _InfoPill(
                  icon: Icons.warning_amber_outlined,
                  label: 'Reorder: $reorder',
                ),
                _InfoPill(
                  icon: supplierName == 'Unassigned'
                      ? Icons.help_outline
                      : Icons.storefront_outlined,
                  label: supplierName,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ?? theme.colorScheme.surfaceContainerHighest;
    final fg = foreground ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
