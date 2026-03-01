import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notifications_list_provider.dart';

/// Groups notifications into the four report categories used
/// on the Reports page.
final groupedReportsProvider =
    Provider<Map<String, List<Map<String, dynamic>>>>((ref) {
  final notifications = ref.watch(notificationsListProvider);

  final stockIn = <Map<String, dynamic>>[];
  final stockOut = <Map<String, dynamic>>[];
  final lowStock = <Map<String, dynamic>>[];
  final newItem = <Map<String, dynamic>>[];

  for (final n in notifications) {
    final raw = (n['category'] ?? '').toString().toLowerCase();

    switch (raw) {
      case 'stock_in':
      case 'in':
        stockIn.add(n);
        break;

      case 'stock_out':
      case 'out':
        stockOut.add(n);
        break;

      case 'low_stock':
        lowStock.add(n);
        break;

      case 'new_item':
      case 'item_added':
        newItem.add(n);
        break;

      default:
        // Ignore other notification types (no_stock, suppliers, etc.)
        break;
    }
  }

  return {
    'stock_in': stockIn,
    'stock_out': stockOut,
    'low_stock': lowStock,
    'new_item': newItem,
  };
});
