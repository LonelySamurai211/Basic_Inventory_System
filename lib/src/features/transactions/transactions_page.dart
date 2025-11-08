import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';
import '../inventory/items_provider.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final items = ref.watch(itemsListProvider);
    final itemLookup = {
      for (final item in items)
        if (item['id'] != null) item['id'] as String: item,
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
                      SizedBox(
                        width: cardWidth,
                        child: _TransactionCard(
                          title:
                              itemLookup[tx['item']?['id']]?['name']
                                  ?.toString() ??
                              tx['item']?['name']?.toString() ??
                              'Unknown item',
                          typeLabel: _typeLabel(tx['type']),
                          quantityLabel: _formatQuantity(
                            tx['type'],
                            tx['quantity'],
                          ),
                          note: tx['note']?.toString(),
                          occurredAt: _formatDate(tx['occurred_at']),
                          type: tx['type']?.toString() ?? 'movement',
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

  Future<void> _showLogTransactionDialog() async {
    if (ref.read(itemsListProvider).isEmpty) {
      await refreshItems(ref);
      if (!mounted) return;
    }
    final items = ref.read(itemsListProvider);
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
    String? selectedItem = items.first['id']?.toString();
    String selectedType = 'in';
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log stock movement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedItem,
                items: items
                    .map(
                      (it) => DropdownMenuItem(
                        value: it['id']?.toString(),
                        child: Text(it['name']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedItem = value),
                decoration: const InputDecoration(labelText: 'Item'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('Stock in')),
                  DropdownMenuItem(value: 'out', child: Text('Stock out')),
                  DropdownMenuItem(
                    value: 'adjustment',
                    child: Text('Adjustment'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
                decoration: const InputDecoration(labelText: 'Movement type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtl,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
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
                final qtyText = qtyCtl.text.trim();
                final quantity =
                    int.tryParse(qtyText.isEmpty ? '0' : qtyText) ?? 0;
                if (selectedItem == null || selectedItem!.isEmpty) return;

                if (selectedType != 'adjustment' && quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a positive quantity.')),
                  );
                  return;
                }

                final payloadQuantity = selectedType == 'adjustment'
                    ? quantity
                    : quantity.abs();
                final note = noteCtl.text.trim().isEmpty
                    ? null
                    : noteCtl.text.trim();

                final ok = await logTransaction(
                  ref,
                  itemId: selectedItem!,
                  type: selectedType,
                  quantity: payloadQuantity,
                  note: note,
                );
                if (!mounted) return;

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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(dynamic rawType) {
    switch (rawType) {
      case 'in':
        return 'Stock in';
      case 'out':
        return 'Stock out';
      case 'adjustment':
        return 'Adjustment';
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
    return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.title,
    required this.typeLabel,
    required this.quantityLabel,
    required this.occurredAt,
    required this.type,
    this.note,
  });

  final String title;
  final String typeLabel;
  final String quantityLabel;
  final String occurredAt;
  final String type;
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
                _MetaPill(icon: Icons.schedule_outlined, label: occurredAt),
              ],
            ),
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
      case 'adjustment':
        return _Tone(
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          icon: Icons.sync_alt_outlined,
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
