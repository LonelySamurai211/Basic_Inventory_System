import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';
import '../notifications/notifications_list_provider.dart';
import '../notifications/notifications_service.dart';
import '../suppliers/suppliers_provider.dart';
import '../transactions/transactions_provider.dart';
import 'items_provider.dart';
import 'widgets/item_dialog.dart';

/// Combined Inventory + Transactions view.
///
/// Shows stock levels with grouped movements per item.
class InventoryTransactionsPage extends ConsumerStatefulWidget {
  const InventoryTransactionsPage({super.key});

  @override
  ConsumerState<InventoryTransactionsPage> createState() =>
      _InventoryTransactionsPageState();
}

class _InventoryTransactionsPageState
    extends ConsumerState<InventoryTransactionsPage> {
  bool _loaded = false;
  String _searchText = '';
  // All / Wet / Dry   (Type of goods filter)
  String _goodsFilter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      refreshItems(ref);
      refreshSuppliers(ref);
      refreshTransactions(ref);
      refreshNotifications(ref);

      // Check for existing low-stock / no-stock notifications
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final items = ref.read(itemsListProvider);
        final notifications = ref.read(notificationsListProvider);

        for (final item in items) {
          final stock = item['stock_qty'] as int? ?? 0;
          final reorderLevel = item['reorder_level'] as int? ?? 0;
          final itemName = item['name'] as String? ?? 'Unknown item';
          final unit = item['unit'] as String? ?? 'pcs';

          if (stock <= reorderLevel) {
            final exists = notifications.any((n) =>
                n['category'] == 'low_stock' &&
                n['message']?.toString().contains(itemName) == true);

            if (!exists) {
              await NotificationsService.lowStock(
                ref: ref,
                itemName: itemName,
                currentStock: stock,
                reorderLevel: reorderLevel,
                unit: unit,
              );
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsListProvider);
    final suppliers = ref.watch(suppliersListProvider);
    final transactions = ref.watch(transactionsProvider);

    final itemLookup = <String, Map<String, dynamic>>{
      for (final item in items)
        if (item['id'] != null) item['id'].toString(): item,
    };

    final supplierLookup = <String, Map<String, dynamic>>{
      for (final supplier in suppliers)
        if (supplier['id'] != null) supplier['id'].toString(): supplier,
    };

    final search = _searchText.trim().toLowerCase();

    // First filter items according to goods filter + search
    final filteredItems = items.where((item) {
      final section =
          item['food_section']?.toString().toLowerCase().trim() ?? '';

      // Type of goods filter (Wet / Dry)
      if (_goodsFilter == 'Wet' && section != 'wet') return false;
      if (_goodsFilter == 'Dry' && section != 'dry') return false;

      // Search by item name
      if (search.isNotEmpty) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        if (!name.contains(search)) return false;
      }

      return true;
    }).toList();

    // Then filter transactions for the filtered items
    final filteredTx = transactions.where((tx) {
      final itemId = _resolveTransactionItemId(tx);
      if (itemId == null) return false;
      final item = itemLookup[itemId];
      if (item == null) return false;

      // Ensure item is in filtered items
      if (!filteredItems.any((fi) => fi['id'].toString() == itemId)) {
        return false;
      }

      // Additional search by note
      if (search.isNotEmpty) {
        final note = tx['note']?.toString().toLowerCase() ?? '';
        if (!note.contains(search)) return false;
      }

      return true;
    }).toList();

    // Group filtered transactions by item id
    final groupedByItem = <String, List<Map<String, dynamic>>>{};
    for (final tx in filteredTx) {
      final itemId = _resolveTransactionItemId(tx);
      if (itemId == null) continue;
      groupedByItem.putIfAbsent(itemId, () => <Map<String, dynamic>>[]).add(tx);
    }

    // Include all filtered items, even those without transactions
    for (final item in filteredItems) {
      final itemId = item['id']?.toString();
      if (itemId != null && !groupedByItem.containsKey(itemId)) {
        groupedByItem[itemId] = [];
      }
    }

    // Sort items by name for stable UI
    final groupedEntries = groupedByItem.entries.toList()
      ..sort((a, b) {
        final aName = itemLookup[a.key]?['name']?.toString() ?? '';
        final bName = itemLookup[b.key]?['name']?.toString() ?? '';
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Inventory',
            subtitle:
                'Review stock levels and every stock in/out movement in one view.',
          ),
          const SizedBox(height: 16),

          // Top toolbar row
          Row(
            children: [
              // LEFT: Buttons
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Add item'),
                  ),
                ],
              ),

              const Spacer(),

              // RIGHT: Search box
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Item name or note',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT: Goods filter capsule
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _goodsFilter = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'All',
                    child: Text('All goods'),
                  ),
                  PopupMenuItem(
                    value: 'Wet',
                    child: Text('Wet goods'),
                  ),
                  PopupMenuItem(
                    value: 'Dry',
                    child: Text('Dry goods'),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_goodsFilter} goods',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (items.isEmpty)
            const EmptyPlaceholder(
              title: 'No items yet',
              message: 'Add inventory items to see them here.',
              icon: Icons.inventory_2_outlined,
            )
          else if (groupedEntries.isEmpty)
            EmptyPlaceholder(
              title: 'Nothing matches your filters',
              message:
                  'Try changing the type of goods filter or search text.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 360.0;
                const spacing = 16.0;
                final maxWidth = constraints.maxWidth;

                final computedColumns = maxWidth <= minCardWidth
                    ? 1
                    : (maxWidth / minCardWidth).floor();
                final columns = computedColumns.clamp(1, 4);
                final cardWidth = columns == 1
                    ? maxWidth
                    : (maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final entry in groupedEntries)
                      _buildTransactionInventoryCard(
                        context,
                        itemId: entry.key,
                        itemTransactions: entry.value,
                        itemLookup: itemLookup,
                        supplierLookup: supplierLookup,
                        cardWidth: cardWidth,
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Card builder (one card per ITEM)

  Widget _buildTransactionInventoryCard(
    BuildContext context, {
    required String itemId,
    required List<Map<String, dynamic>> itemTransactions,
    required Map<String, Map<String, dynamic>> itemLookup,
    required Map<String, Map<String, dynamic>> supplierLookup,
    required double cardWidth,
  }) {
    final theme = Theme.of(context);

    final item = itemLookup[itemId];
    if (item == null) {
      return const SizedBox.shrink();
    }

    // Sort movements newest → oldest
    final txs = List<Map<String, dynamic>>.from(itemTransactions)
      ..sort((a, b) {
        final da = _parseDateValue(
                a['transaction_date'] ?? a['occurred_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = _parseDateValue(
                b['transaction_date'] ?? b['occurred_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

    final hasTransactions = txs.isNotEmpty;
    final latestTx = hasTransactions ? txs.first : <String, dynamic>{};
    final itemName = item['name']?.toString() ?? 'Unknown item';
    final description = item['description']?.toString();
    final unit = (item['unit']?.toString().isNotEmpty ?? false)
        ? item['unit'].toString()
        : 'pcs';

    final type = hasTransactions
        ? (latestTx['type']?.toString().toLowerCase() ?? '')
        : '';
    final typeLabel = hasTransactions
        ? (type == 'out'
            ? 'Stock out'
            : type == 'in'
                ? 'Stock in'
                : 'Movement')
        : 'No movements yet';

    final quantityLabel =
        hasTransactions ? _formatTransactionQuantity(latestTx) : '-----';
    final occurredAt =
        hasTransactions ? _formatTransactionDate(latestTx) : '';

    final supplierId = hasTransactions
        ? (latestTx['supplier_id'] ?? item['supplier_id'])?.toString()
        : item['supplier_id']?.toString();
    final supplier = supplierId != null ? supplierLookup[supplierId] : null;
    final supplierName =
        supplier?['name']?.toString() ?? 'Unassigned supplier';

    final manufacturingDate = _formatBatchDate(
      hasTransactions
          ? (latestTx['manufactured_on'] ?? item['manufactured_on'])
          : item['manufactured_on'],
    );
    final deliveryDate = _formatBatchDate(
      hasTransactions
          ? (latestTx['delivered_on'] ?? item['delivered_on'])
          : item['delivered_on'],
    );
    final expiryDate = _formatBatchDate(
      hasTransactions
          ? (latestTx['expiry_on'] ?? item['expiry_on'])
          : item['expiry_on'],
    );

    final currentStock = _coerceInt(item['stock_qty']);
    final note = hasTransactions ? latestTx['note']?.toString() : null;

    final section = item['food_section']?.toString();
    final typeOfGoodsDisplay =
        section == null || section.isEmpty ? '-' : section;

    final tone = hasTransactions
        ? _toneForType(theme.colorScheme, type)
        : _Tone(
            background: theme.colorScheme.surfaceContainerHighest,
            foreground: theme.colorScheme.onSurface,
            icon: Icons.inventory_2_outlined,
          );

    return SizedBox(
      width: cardWidth,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + quantity badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),

                  // LOG TRANSACTION BUTTON
                  IconButton(
                    tooltip: 'Log stock movement',
                    icon: const Icon(Icons.playlist_add_outlined),
                    onPressed: () =>
                        _showLogTransactionDialog(preSelectedItemId: itemId),
                  ),

                  // DELETE ITEM BUTTON
                  IconButton(
                    tooltip: 'Delete item',
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete item'),
                          content: Text(
                            'Are you sure you want to delete "$itemName"?\n'
                            'This will remove all of its stock and transactions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: const ButtonStyle(
                                backgroundColor:
                                    WidgetStatePropertyAll(Colors.redAccent),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await deleteItemFromProvider(ref, itemId);
                      }
                    },
                  ),

                  _MetaPill(
                    icon: Icons.inventory_outlined,
                    label: 'Qty $quantityLabel',
                    background: tone.background,
                    foreground: tone.foreground,
                  ),
                ],
              ),

              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],

              const SizedBox(height: 6),
              Text(
                'Type of goods: $typeOfGoodsDisplay',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: tone.icon,
                    label: typeLabel,
                    background: tone.background,
                    foreground: tone.foreground,
                  ),
                  if (occurredAt.isNotEmpty)
                    _MetaPill(
                      icon: Icons.schedule_outlined,
                      label: occurredAt,
                    ),
                  _MetaPill(
                    icon: Icons.inventory_2_outlined,
                    label: 'In stock: $currentStock $unit',
                    isBlinking: currentStock == 0,
                  ),
                  _MetaPill(
                    icon: Icons.business_outlined,
                    label: supplierName,
                  ),
                  if (note != null && note.isNotEmpty)
                    _MetaPill(
                      icon: Icons.sticky_note_2_outlined,
                      label: note,
                    ),
                  if (txs.length > 1)
                    _MetaPill(
                      icon: Icons.history,
                      label: '${txs.length} movements',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 24),

              // Batches section
              if (txs
                  .where((tx) =>
                      tx['type']?.toString().toLowerCase() == 'in')
                  .isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Batches',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (txs
                            .where((tx) =>
                                tx['type']?.toString().toLowerCase() == 'in')
                            .length >
                        3)
                      TextButton(
                        onPressed: () => _showExpandBatchesDialog(
                          context,
                          txs
                              .where((tx) =>
                                  tx['type']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'in')
                              .toList(),
                          supplierLookup,
                        ),
                        child: const Text('Expand'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...txs
                    .where((tx) =>
                        tx['type']?.toString().toLowerCase() == 'in')
                    .take(3)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Batch ${entry.key + 1}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showBatchDetails(
                                context,
                                entry.value,
                                supplierLookup,
                              ),
                              child: const Text('View'),
                            ),
                          ],
                        ),
                      ),
                    ),
              ] else ...[
                _DetailRow(
                    label: 'Manufacturing date', value: manufacturingDate),
                _DetailRow(label: 'Delivery date', value: deliveryDate),
                _DetailRow(label: 'Expiry date', value: expiryDate),
              ],

              if (txs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent movements',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (txs.length > 3)
                      TextButton(
                        onPressed: () =>
                            _showExpandMovementsDialog(context, txs),
                        child: const Text('Expand'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final tx in txs.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatTransactionDate(tx)} • ${tx['type']?.toString().toUpperCase() ?? ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          _formatTransactionQuantity(tx),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────────────────────

  Future<void> _showAddItemDialog() async {
    final success =
        await showInventoryItemDialog(context: context, ref: ref);
    if (!mounted || !success) return;
    await Future.wait([
      refreshItems(ref),
      refreshNotifications(ref),
      refreshTransactions(ref),
    ]);
  }

  Future<void> _showLogTransactionDialog({String? preSelectedItemId}) async {
    if (ref.read(itemsListProvider).isEmpty) {
      await refreshItems(ref);
      if (!mounted) return;
    }
    final items = ref.read(itemsListProvider);

    if (ref.read(suppliersListProvider).isEmpty) {
      await refreshSuppliers(ref);
      if (!mounted) return;
    }
    final suppliers = ref.read(suppliersListProvider);

    if (items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Add inventory items before logging transactions.',
            ),
          ),
        );
      }
      return;
    }

    final qtyCtl = TextEditingController();
    final noteCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedItem = preSelectedItemId ?? items.first['id']?.toString();
    String selectedType = 'in';
    DateTime selectedDate = DateTime.now();
    Map<String, dynamic> currentItem = items.firstWhere(
      (element) => element['id']?.toString() == selectedItem,
      orElse: () => items.first,
    );
    String? selectedSupplier = currentItem['supplier_id']?.toString();
    DateTime? manufacturedOn =
        _parseDateValue(currentItem['manufactured_on']);
    DateTime? deliveredOn =
        _parseDateValue(currentItem['delivered_on']) ?? DateTime.now();
    DateTime? expiryOn = _parseDateValue(currentItem['expiry_on']);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          const spacing = 16.0;
          const minWidth = 360.0;
          const maxWidth = 720.0;
          final availableWidth = MediaQuery.sizeOf(ctx).width - 96;
          final formWidth =
              math.max(minWidth, math.min(maxWidth, availableWidth));
          final isWide = formWidth >= 520;
          final fieldWidth =
              isWide ? (formWidth - spacing) / 2 : formWidth;

          Widget wrapField(
            Widget child, {
            bool spanFullWidth = false,
          }) {
            return SizedBox(
              width: spanFullWidth || !isWide ? formWidth : fieldWidth,
              child: child,
            );
          }

          final children = <Widget>[
            wrapField(
              DropdownButtonFormField<String>(
                key: ValueKey(selectedItem),
                value: selectedItem,
                decoration: const InputDecoration(labelText: 'Item'),
                items: items
                    .map(
                      (it) => DropdownMenuItem(
                        value: it['id']?.toString(),
                        child: Text(it['name']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Select item' : null,
                onChanged: preSelectedItemId == null
                    ? (value) {
                        if (value == null) return;
                        setState(() {
                          selectedItem = value;
                          currentItem = items.firstWhere(
                            (element) =>
                                element['id']?.toString() == value,
                            orElse: () => items.first,
                          );
                          if (selectedType == 'out') {
                            selectedSupplier =
                                currentItem['supplier_id']?.toString();
                            manufacturedOn = _parseDateValue(
                                currentItem['manufactured_on']);
                            deliveredOn =
                                _parseDateValue(currentItem['delivered_on']) ??
                                    DateTime.now();
                            expiryOn = _parseDateValue(
                                currentItem['expiry_on']);
                          }
                        });
                      }
                    : null,
              ),
              spanFullWidth: true,
            ),
            wrapField(
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration:
                    const InputDecoration(labelText: 'Movement type'),
                items: const [
                  DropdownMenuItem(
                    value: 'in',
                    child: Text('Stock in'),
                  ),
                  DropdownMenuItem(
                    value: 'out',
                    child: Text('Stock out'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedType = value;
                    if (selectedType == 'out') {
                      selectedSupplier =
                          currentItem['supplier_id']?.toString();
                      manufacturedOn =
                          _parseDateValue(currentItem['manufactured_on']);
                      deliveredOn =
                          _parseDateValue(currentItem['delivered_on']) ??
                              DateTime.now();
                      expiryOn =
                          _parseDateValue(currentItem['expiry_on']);
                    }
                  });
                },
              ),
            ),
            wrapField(
              TextFormField(
                controller: qtyCtl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive number';
                  }
                  return null;
                },
              ),
            ),
          ];

          if (suppliers.isNotEmpty) {
            children.add(
              wrapField(
                DropdownButtonFormField<String?>(
                  key: ValueKey('${selectedType}_$selectedSupplier'),
                  value: selectedSupplier,
                  decoration: InputDecoration(
                    labelText: selectedType == 'in'
                        ? 'Supplier'
                        : 'Supplier (locked for stock out)',
                  ),
                  validator: (_) {
                    if (selectedType == 'in' &&
                        (selectedSupplier == null ||
                            selectedSupplier!.isEmpty)) {
                      return 'Select a supplier';
                    }
                    return null;
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...suppliers.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s['id']?.toString(),
                        child: Text(s['name']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: selectedType == 'in'
                      ? (value) =>
                          setState(() => selectedSupplier = value)
                      : null,
                ),
              ),
            );
          } else {
            children.add(
              wrapField(
                const Text('Add suppliers to tag stock movements.'),
                spanFullWidth: true,
              ),
            );
          }

          children.addAll([
            wrapField(
              _DatePickerFormField(
                key: ValueKey(
                    'tx_date_${selectedDate.toIso8601String()}'),
                label: 'Transaction date',
                value: selectedDate,
                required: false,
                enabled: true,
                dialogContext: context,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDate = value);
                  }
                },
              ),
            ),
            wrapField(
              _DatePickerFormField(
                key: ValueKey(
                    'mfg_${manufacturedOn?.toIso8601String() ?? 'null'}'),
                label: 'Manufacturing date (optional)',
                value: manufacturedOn,
                required: false,
                enabled: selectedType == 'in',
                dialogContext: context,
                onChanged: (value) =>
                    setState(() => manufacturedOn = value),
              ),
            ),
            wrapField(
              _DatePickerFormField(
                key: ValueKey(
                    'del_${deliveredOn?.toIso8601String() ?? 'null'}'),
                label: 'Delivery date (optional)',
                value: deliveredOn,
                required: false,
                enabled: selectedType == 'in',
                dialogContext: context,
                onChanged: (value) =>
                    setState(() => deliveredOn = value),
              ),
            ),
            wrapField(
              _DatePickerFormField(
                key: ValueKey(
                    'exp_${expiryOn?.toIso8601String() ?? 'null'}'),
                label: 'Expiry date (optional)',
                value: expiryOn,
                required: false,
                enabled: selectedType == 'in',
                dialogContext: context,
                onChanged: (value) =>
                    setState(() => expiryOn = value),
              ),
            ),
            wrapField(
              TextFormField(
                controller: noteCtl,
                decoration: const InputDecoration(
                    labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              spanFullWidth: true,
            ),
          ]);

          return AlertDialog(
            title: const Text('Log stock movement'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: formWidth,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final isValid =
                            formKey.currentState?.validate() ?? false;
                        if (!isValid || selectedItem == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Fix the highlighted fields.'),
                            ),
                          );
                          return;
                        }
                        setState(() => submitting = true);

                        // Refresh items to get latest stock
                        await refreshItems(ref);
                        if (!mounted) return;
                        final refreshedItems =
                            ref.read(itemsListProvider);
                        final refreshedCurrentItem =
                            refreshedItems.firstWhere(
                          (element) =>
                              element['id']?.toString() ==
                              selectedItem,
                          orElse: () => currentItem,
                        );

                        final note = noteCtl.text.trim().isEmpty
                            ? null
                            : noteCtl.text.trim();

                        final supplierForLog = selectedSupplier ??
                            refreshedCurrentItem['supplier_id']
                                ?.toString();
                        final manufacturedForLog = manufacturedOn ??
                            _parseDateValue(
                                refreshedCurrentItem['manufactured_on']);
                        final deliveredForLog =
                            deliveredOn ?? DateTime.now();
                        final expiryForLog = expiryOn ??
                            _parseDateValue(
                                refreshedCurrentItem['expiry_on']);

                        final quantity =
                            int.parse(qtyCtl.text.trim()).abs();

                        // Supply limit check for stock in
                        if (selectedType == 'in') {
                          final supplyLimit = _coerceInt(
                              refreshedCurrentItem['supply_limit']);
                          final currentStock = _coerceInt(
                              refreshedCurrentItem['stock_qty']);
                          if (supplyLimit > 0 &&
                              currentStock >= supplyLimit) {
                            setState(() => submitting = false);
                            await showDialog(
                              context: ctx,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Inventory Full'),
                                content: Text(
                                  'Cannot add stock: inventory is already at or above the supply limit of $supplyLimit ${refreshedCurrentItem['unit'] ?? 'pcs'}. '
                                  'Current stock: $currentStock.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                        }

                        final ok = await logTransaction(
                          ref,
                          itemId: selectedItem!,
                          type: selectedType,
                          quantity: quantity,
                          transactionDate: selectedDate,
                          note: note,
                          supplierId: supplierForLog,
                          manufacturedOn: manufacturedForLog,
                          deliveredOn: deliveredForLog,
                          expiryOn: expiryForLog,
                        );

                        // Reorder / no-stock notifications
                        if (ok && selectedType == 'out') {
                          final reorderLevel = _coerceInt(
                              refreshedCurrentItem['reorder_level']);
                          final currentStock =
                              _coerceInt(refreshedCurrentItem['stock_qty']);
                          final newStock = currentStock - quantity;

                          if (reorderLevel > 0 &&
                              newStock <= reorderLevel) {
                            await showDialog(
                              context: ctx,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Reorder Alert'),
                                content: Text(
                                  'Stock for "${refreshedCurrentItem['name'] ?? 'Unknown item'}" is now at $newStock ${refreshedCurrentItem['unit'] ?? 'pcs'}, '
                                  'which is at or below the reorder level of $reorderLevel. Consider reordering.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (newStock <= 0) {
                            await NotificationsService.noStock(
                              ref: ref,
                              itemName: refreshedCurrentItem['name']
                                      ?.toString() ??
                                  'Unknown item',
                              unit: refreshedCurrentItem['unit']
                                      ?.toString() ??
                                  'pcs',
                            );
                          }
                        }

                        if (!mounted) return;
                        setState(() => submitting = false);

                        if (ok) {
                          await Future.wait([
                            refreshItems(ref),
                            refreshTransactions(ref),
                          ]);
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Transaction logged'),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to log transaction'),
                            ),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBatchDetails(
    BuildContext context,
    Map<String, dynamic> tx,
    Map<String, Map<String, dynamic>> supplierLookup,
  ) async {
    final supplierId = tx['supplier_id']?.toString();
    final supplier =
        supplierId != null ? supplierLookup[supplierId] : null;
    final supplierName =
        supplier?['name']?.toString() ?? 'Unassigned supplier';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batch Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Supplier', value: supplierName),
              _DetailRow(
                label: 'Manufacturing date',
                value: _formatBatchDate(tx['manufactured_on']),
              ),
              _DetailRow(
                label: 'Delivery date',
                value: _formatBatchDate(tx['delivered_on']),
              ),
              _DetailRow(
                label: 'Expiry date',
                value: _formatBatchDate(tx['expiry_on']),
              ),
              _DetailRow(
                label: 'Quantity',
                value: '${_coerceInt(tx['quantity'])}',
              ),
              if (tx['note'] != null &&
                  tx['note'].toString().isNotEmpty)
                _DetailRow(
                  label: 'Note',
                  value: tx['note'].toString(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpandBatchesDialog(
    BuildContext context,
    List<Map<String, dynamic>> batches,
    Map<String, Map<String, dynamic>> supplierLookup,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('All Batches'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: batches
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Batch ${entry.key + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showBatchDetails(
                              context, entry.value, supplierLookup),
                          child: const Text('View'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final transactionId =
                                entry.value['id']?.toString();
                            if (transactionId == null) return;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Delete transaction'),
                                content: const Text(
                                  'Are you sure you want to delete this batch transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: const ButtonStyle(
                                      backgroundColor:
                                          WidgetStatePropertyAll(
                                              Colors.redAccent),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await deleteTransaction(ref, transactionId);
                              await refreshItems(ref);
                              await refreshTransactions(ref);
                              if (mounted) {
                                Navigator.of(ctx).pop();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExpandMovementsDialog(
    BuildContext context,
    List<Map<String, dynamic>> txs,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('All Recent Movements'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: txs
                .map(
                  (tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_formatTransactionDate(tx)} • ${tx['type']?.toString().toUpperCase() ?? ''}',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          _formatTransactionQuantity(tx),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final transactionId =
                                tx['id']?.toString();
                            if (transactionId == null) return;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Delete transaction'),
                                content: const Text(
                                  'Are you sure you want to delete this movement transaction?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: const ButtonStyle(
                                      backgroundColor:
                                          WidgetStatePropertyAll(
                                              Colors.redAccent),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await deleteTransaction(ref, transactionId);
                              await refreshItems(ref);
                              await refreshTransactions(ref);
                              if (mounted) {
                                Navigator.of(ctx).pop();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helpers

  String? _resolveTransactionItemId(Map<String, dynamic> tx) {
    final direct = tx['item_id'];
    if (direct != null) return direct.toString();
    final nested = tx['item'];
    if (nested is Map && nested['id'] != null) {
      return nested['id'].toString();
    }
    return null;
  }

  String _formatTransactionDate(Map<String, dynamic> tx) {
    final raw = tx['transaction_date'] ?? tx['occurred_at'];
    if (raw is DateTime) {
      return DateFormat('MMM d, yyyy').format(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat('MMM d, yyyy').format(parsed);
      }
      return raw;
    }
    return '';
  }

  String _formatTransactionQuantity(Map<String, dynamic> tx) {
    final qty = _coerceInt(tx['quantity']);
    final type = tx['type']?.toString().toLowerCase();
    final prefix = type == 'out' ? '-' : '+';
    return '$prefix$qty';
  }

  int _coerceInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime? _parseDateValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  String _formatBatchDate(dynamic raw) {
    if (raw == null) return '-';
    if (raw is DateTime) {
      return DateFormat('MMM d, yyyy').format(raw);
    }
    final asString = raw.toString();
    if (asString.isEmpty) return '-';
    final parsed = DateTime.tryParse(asString);
    if (parsed != null) {
      return DateFormat('MMM d, yyyy').format(parsed);
    }
    return asString;
  }
}

// Small reused UI bits

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatefulWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.background,
    this.foreground,
    this.isBlinking = false,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;
  final bool isBlinking;

  @override
  State<_MetaPill> createState() => _MetaPillState();
}

class _MetaPillState extends State<_MetaPill> {
  Timer? _timer;
  bool _isRed = true;

  @override
  void initState() {
    super.initState();
    if (widget.isBlinking) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          setState(() => _isRed = !_isRed);
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant _MetaPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      _timer?.cancel();
      _timer = null;
      if (widget.isBlinking) {
        _isRed = true;
        _timer = Timer.periodic(
          const Duration(milliseconds: 500),
          (timer) {
            setState(() => _isRed = !_isRed);
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.isBlinking
        ? (_isRed ? Colors.red : Colors.red.shade200)
        : (widget.background ??
            theme.colorScheme.surfaceContainerHighest);
    final fg = widget.foreground ?? theme.colorScheme.onSurface;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style:
                theme.textTheme.bodySmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _Tone {
  const _Tone({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

_Tone _toneForType(ColorScheme scheme, String type) {
  final t = type.toLowerCase();
  if (t == 'in') {
    return _Tone(
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      icon: Icons.call_received_outlined,
    );
  }
  if (t == 'out') {
    return _Tone(
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      icon: Icons.call_made_outlined,
    );
  }
  return _Tone(
    background: scheme.surfaceContainerHighest,
    foreground: scheme.onSurface,
    icon: Icons.drag_indicator_rounded,
  );
}

class _DatePickerFormField extends StatelessWidget {
  const _DatePickerFormField({
    super.key,
    required this.label,
    required this.value,
    required this.required,
    required this.enabled,
    required this.dialogContext,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final bool required;
  final bool enabled;
  final BuildContext dialogContext;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value == null
          ? ''
          : DateFormat('MMM d, yyyy').format(value!),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      validator: (val) {
        if (!required) return null;
        if (val == null || val.isEmpty) {
          return 'Select a date';
        }
        return null;
      },
      onTap: !enabled
          ? null
          : () async {
              final selected = await showDatePicker(
                context: dialogContext,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              onChanged(selected);
            },
    );
  }
}
