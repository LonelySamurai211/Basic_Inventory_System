import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';
import '../inventory/items_provider.dart';
import '../suppliers/suppliers_provider.dart';
import 'transactions_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      refreshTransactions(ref);
      if (ref.read(itemsListProvider).isEmpty) {
        refreshItems(ref);
      }
      if (ref.read(suppliersListProvider).isEmpty) {
        refreshSuppliers(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final items = ref.watch(itemsListProvider);
    final suppliers = ref.watch(suppliersListProvider);
    final itemLookup = {
      for (final item in items)
        if (item['id'] != null) item['id'] as String: item,
    };
    final supplierLookup = {
      for (final supplier in suppliers)
        if (supplier['id'] != null)
          supplier['id'].toString(): supplier,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Transaction Log',
            subtitle: 'Track stock in/out movements for every supply.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () {
                _showLogTransactionDialog();
              },
              icon: const Icon(Icons.playlist_add_outlined),
              label: const Text('Log transaction'),
            ),
          ),
          const SizedBox(height: 24),
          if (transactions.isEmpty)
            EmptyPlaceholder(
              title: 'No movements recorded yet',
              message:
                  'Log receipts and consumption to keep your counts current.',
              icon: Icons.compare_arrows_outlined,
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
                    for (final tx in transactions)
                      _transactionCardFor(
                        context,
                        tx: tx,
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

  Future<void> _showLogTransactionDialog() async {
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
            content: Text('Add inventory items before logging transactions.'),
          ),
        );
      }
      return;
    }

    final qtyCtl = TextEditingController();
    final noteCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedItem = items.first['id']?.toString();
    String selectedType = 'in';
    DateTime selectedDate = DateTime.now();
    Map<String, dynamic> currentItem = items.firstWhere(
      (element) => element['id']?.toString() == selectedItem,
      orElse: () => items.first,
    );
    String? selectedSupplier = currentItem['supplier_id']?.toString();
    DateTime? manufacturedOn = _parseDateValue(currentItem['manufactured_on']);
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
          final formWidth = math.max(
            minWidth,
            math.min(maxWidth, availableWidth),
          );
          final isWide = formWidth >= 520;
          final fieldWidth = isWide ? (formWidth - spacing) / 2 : formWidth;

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
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedItem = value;
                    currentItem = items.firstWhere(
                      (element) => element['id']?.toString() == value,
                      orElse: () => items.first,
                    );
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
              spanFullWidth: true,
            ),
            wrapField(
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration:
                    const InputDecoration(labelText: 'Movement type'),
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('Stock in')),
                  DropdownMenuItem(value: 'out', child: Text('Stock out')),
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
                      ? (value) => setState(() => selectedSupplier = value)
                      : null,
                ),
              ),
            );
          } else {
            children.add(
              wrapField(
                const Text(
                  'Add suppliers to tag stock movements.',
                ),
                spanFullWidth: true,
              ),
            );
          }

          children.addAll([
            wrapField(
              _DatePickerFormField(
                key: ValueKey('tx_date_${selectedDate.toIso8601String()}'),
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
                onChanged: (value) => setState(() => expiryOn = value),
              ),
            ),
            wrapField(
              TextFormField(
                controller: noteCtl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
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
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                        final isValid = formKey.currentState?.validate() ?? false;
                        if (!isValid || selectedItem == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Fix the highlighted fields.'),
                            ),
                          );
                          return;
                        }
                        setState(() => submitting = true);

                        final note = noteCtl.text.trim().isEmpty
                            ? null
                            : noteCtl.text.trim();

                        final supplierForLog = selectedSupplier ??
                            currentItem['supplier_id']?.toString();
                        final manufacturedForLog = manufacturedOn ??
                          _parseDateValue(currentItem['manufactured_on']);
                        final deliveredForLog =
                          deliveredOn ?? DateTime.now();
                        final expiryForLog = expiryOn ??
                          _parseDateValue(currentItem['expiry_on']);

                        final ok = await logTransaction(
                          ref,
                          itemId: selectedItem!,
                          type: selectedType,
                          quantity: int.parse(qtyCtl.text.trim()).abs(),
                          transactionDate: selectedDate,
                          note: note,
                          supplierId: supplierForLog,
                          manufacturedOn: manufacturedForLog,
                          deliveredOn: deliveredForLog,
                          expiryOn: expiryForLog,
                        );
                        if (!mounted) return;
                        setState(() => submitting = false);

                        if (ok) {
                          await refreshItems(ref);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Transaction recorded')),
                          );
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to record transaction'),
                            ),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _transactionCardFor(
    BuildContext context, {
    required Map<String, dynamic> tx,
    required Map<String, Map<String, dynamic>> itemLookup,
    required Map<String, Map<String, dynamic>> supplierLookup,
    required double cardWidth,
  }) {
    final txItem = tx['item'] as Map<String, dynamic>?;
    final itemName = itemLookup[txItem?['id']]?['name']?.toString() ??
        txItem?['name']?.toString() ??
        'Unknown item';
    final supplierId = (tx['supplier_id'] ?? txItem?['supplier_id'])?.toString();
    final supplierData = supplierId != null ? supplierLookup[supplierId] : null;
    final supplierName = supplierData?['name']?.toString() ?? 'Unassigned';
    final manufacturingDate = tx['manufactured_on'] ?? txItem?['manufactured_on'];
    final deliveryDate = tx['delivered_on'] ?? txItem?['delivered_on'];
    final expiryDate = tx['expiry_on'] ?? txItem?['expiry_on'];

    return SizedBox(
      width: cardWidth,
      child: _TransactionCard(
        title: itemName,
        typeLabel: _typeLabel(tx['type']),
        quantityLabel: _formatQuantity(tx['type'], tx['quantity']),
        note: tx['note']?.toString(),
        occurredAt: _formatDate(tx['occurred_at']),
        type: tx['type']?.toString() ?? 'movement',
        supplierName: supplierName,
        manufacturingDate: _formatBatchDate(manufacturingDate),
        deliveryDate: _formatBatchDate(deliveryDate),
        expiryDate: _formatBatchDate(expiryDate),
      ),
    );
  }

  String _typeLabel(dynamic rawType) {
    switch (rawType) {
      case 'in':
        return 'Stock in';
      case 'out':
        return 'Stock out';
      default:
        return 'Movement';
    }
  }

  String _formatQuantity(dynamic rawType, dynamic rawQty) {
    final qty = int.tryParse(rawQty?.toString() ?? '') ?? 0;
    if (rawType == 'out') return '-$qty';
    return qty.toString();
  }

  String _formatDate(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '');
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
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

  DateTime? _parseDateValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.title,
    required this.typeLabel,
    required this.quantityLabel,
    required this.occurredAt,
    required this.type,
    required this.supplierName,
    required this.manufacturingDate,
    required this.deliveryDate,
    required this.expiryDate,
    this.note,
  });

  final String title;
  final String typeLabel;
  final String quantityLabel;
  final String occurredAt;
  final String type;
  final String supplierName;
  final String manufacturingDate;
  final String deliveryDate;
  final String expiryDate;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = _toneForType(scheme);

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
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                _MetaPill(
                  icon: Icons.inventory_outlined,
                  label: 'Qty $quantityLabel',
                  background: tone.background,
                  foreground: tone.foreground,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: tone.icon,
                  label: typeLabel,
                  background: tone.background,
                  foreground: tone.foreground,
                ),
                if (note != null && note!.isNotEmpty)
                  _MetaPill(icon: Icons.sticky_note_2_outlined, label: note!),
                if (occurredAt.isNotEmpty)
                  _MetaPill(
                    icon: Icons.schedule_outlined,
                    label: 'Date: $occurredAt',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 24),
            _DetailRow(label: 'Supplier', value: supplierName),
            _DetailRow(label: 'Manufacturing date', value: manufacturingDate),
            _DetailRow(label: 'Delivery date', value: deliveryDate),
            _DetailRow(label: 'Expiry date', value: expiryDate),
          ],
        ),
      ),
    );
  }

  _Tone _toneForType(ColorScheme scheme) {
    switch (type) {
      case 'in':
        return _Tone(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          icon: Icons.call_received_outlined,
        );
      case 'out':
        return _Tone(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          icon: Icons.call_made_outlined,
        );
      default:
        return _Tone(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
          icon: Icons.compare_arrows_outlined,
        );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerFormField extends StatelessWidget {
  const _DatePickerFormField({
    super.key,
    required this.label,
    required this.value,
    required this.dialogContext,
    required this.onChanged,
    this.required = false,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final BuildContext dialogContext;
  final ValueChanged<DateTime?> onChanged;
  final bool required;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (selected) {
        if (!enabled) return null;
        if (required && selected == null) {
          return 'Required';
        }
        return null;
      },
      builder: (state) {
        final displayValue = state.value ?? value;
        final labelText = enabled ? label : '$label (view only)';
        final text = displayValue != null
            ? DateFormat('MMM d, yyyy').format(displayValue)
            : (enabled ? 'Select date' : 'Not captured');
        return InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: displayValue ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    onChanged(picked);
                    state.didChange(picked);
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: labelText,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(text),
          ),
        );
      },
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
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
