import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/notifications_list_provider.dart';
import 'package:intl/intl.dart';

class ReportTile extends ConsumerWidget {
  final Map<String, dynamic> data;

  const ReportTile({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.receipt_long),
      title: Text(
        (data['title'] ?? '') as String,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      // Keep the list preview minimal and professional. Full text
      // is only shown inside the "View details" dialog.
      subtitle: null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ReportDetailsDialog(data: data),
              );
            },
            child: const Text("View details"),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Delete Report'),
                    content: const Text(
                        'Are you sure you want to delete this report?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                final id = data['id']?.toString();
                if (id != null) {
                  await ref
                      .read(notificationsListProvider.notifier)
                      .delete(id);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

//
// ─────────────────────────────────────────────────────────────
//   REPORT DETAILS DIALOG
// ─────────────────────────────────────────────────────────────w 
//

class ReportDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReportDetailsDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Raw values coming from the notifications table.
    final String rawCategory = (data['category'] ?? '').toString();
    final String itemName =
        (data['item_name'] ?? data['itemName'] ?? '').toString();
    final String supplierName =
        (data['supplier_name'] ?? data['supplier'] ?? '').toString();

    final dynamic quantityRaw = data['quantity'];
    final int? quantity = quantityRaw is int
        ? quantityRaw
        : int.tryParse(quantityRaw?.toString() ?? '');

    final String unit = (data['unit'] ?? '').toString();

    final String transactionDateRaw =
        (data['transaction_date'] ?? '').toString();
    final String createdAtRaw = (data['created_at'] ?? '').toString();

    DateTime? _tryParse(String value) =>
        value.isEmpty ? null : DateTime.tryParse(value);

    final DateTime? transactionDate = _tryParse(transactionDateRaw);
    final DateTime? createdAt = _tryParse(createdAtRaw);

    final String formattedDate = transactionDate != null
        ? DateFormat('MMM d, yyyy').format(transactionDate)
        : (createdAt != null
            ? DateFormat('MMM d, yyyy').format(createdAt)
            : '—');

    final String formattedTime = createdAt != null
        ? DateFormat('hh:mm a').format(createdAt)
        : '—';

    // Human-friendly category label
    final String categoryLabel;
    switch (rawCategory.toLowerCase()) {
      case 'stock_in':
      case 'stock in':
        categoryLabel = 'Stock In';
        break;
      case 'stock_out':
      case 'stock out':
        categoryLabel = 'Stock Out';
        break;
      case 'low_stock':
      case 'low stock':
        categoryLabel = 'Low Stock';
        break;
      case 'new_item':
      case 'new item':
        categoryLabel = 'New Item';
        break;
      default:
        categoryLabel =
            rawCategory.isEmpty ? 'Report' : rawCategory;
        break;
    }

    final String message = (data['message'] ?? '').toString();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text('Report Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemName.isNotEmpty) Text('Item: $itemName'),
          if (supplierName.isNotEmpty) Text('Supplier: $supplierName'),
          if (quantity != null)
            Text('Quantity: $quantity${unit.isNotEmpty ? ' $unit' : ''}'),
          Text('Transaction Date: $formattedDate'),
          Text('Recorded Time: $formattedTime'),
          Text('Category: $categoryLabel'),
          const SizedBox(height: 16),
          const Text(
            'Description:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            message.isEmpty
                ? 'No additional details are available for this report.'
                : message,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
