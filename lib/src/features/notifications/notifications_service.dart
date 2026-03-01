import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifications_list_provider.dart';
import './data/notifications_repository.dart';
import 'package:intl/intl.dart';

class NotificationsService {
  static Future<void> _push(
    WidgetRef ref,
    Map<String, dynamic> data,
  ) async {
    final newItem = await NotificationsRepository.insertNotification(data);
    if (newItem != null) {
      ref.read(notificationsListProvider.notifier).upsert(newItem);
    }
  }

  static String formatDate(DateTime date) {
    // Example: Fri, Dec 5, 2025
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  // ─────────────────────────────────────────────────────────────
  // ITEM ADDED → goes to NEW ITEM REPORTS
  // ─────────────────────────────────────────────────────────────
  static Future<void> itemAdded({
    required WidgetRef ref,
    required String itemName,
    String? supplierName,
    required String? unit,
  }) async {
    final now = DateTime.now();
    final formattedDate = formatDate(now);

    // Message shown under "NEW ITEM REPORTS"
    final msg = (supplierName == null || supplierName.isEmpty)
        ? "$itemName was added to the inventory ($unit) on $formattedDate."
        : "$itemName was added to the inventory ($unit) from $supplierName on $formattedDate.";

    await _push(ref, {
      // Important: this routes the entry to NEW ITEM REPORTS
      'category': 'new_item',
      'title': 'New Item Added',
      'message': msg,
      'is_read': false,
      'created_at': now.toIso8601String(),
      'item_name': itemName,
      'supplier_name': supplierName,
      'unit': unit,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // STOCK MOVEMENT (IN / OUT) → STOCK IN / STOCK OUT REPORTS
  // ─────────────────────────────────────────────────────────────
  static Future<void> stockMovement({
    required WidgetRef ref,
    required String type, // 'in' or 'out' from transactions table
    required int quantity,
    required String itemName,
    required String? supplierName,
    required String unit, // IMPORTANT: unit comes from items table
    required DateTime transactionDate,
  }) async {
    final now = DateTime.now();

    // Normalise to the categories used by the Reports page.
    final normalizedType =
        (type == 'out' || type == 'stock_out') ? 'stock_out' : 'stock_in';

    final formattedDate = formatDate(transactionDate);

    String msg;
    if (normalizedType == 'stock_out') {
      msg = "$quantity $unit removed from $itemName on $formattedDate.";
    } else {
      msg = (supplierName == null || supplierName.isEmpty)
          ? "$quantity $unit added to $itemName on $formattedDate."
          : "$quantity $unit added to $itemName from $supplierName on $formattedDate.";
    }

    final title = normalizedType == 'stock_out'
        ? "Item, Stock Out"
        : "Item, Stock In";

    await _push(ref, {
      'category': normalizedType,
      'title': title,
      'message': msg,
      'is_read': false,
      'created_at': now.toIso8601String(),
      // extra structured fields for Reports page
      'item_name': itemName,
      'supplier_name': supplierName,
      'quantity': quantity,
      'unit': unit,
      'transaction_date': transactionDate.toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LOW STOCK
  // ─────────────────────────────────────────────────────────────
  static Future<void> lowStock({
    required WidgetRef ref,
    required String itemName,
    required int currentStock,
    required int reorderLevel,
    required String unit,
  }) async {
    await _push(ref, {
      'category': 'low_stock',
      'title': 'Item, Low Stock',
      'message':
          '$itemName has reached the low-stock threshold: $currentStock $unit remaining (reorder level: $reorderLevel $unit).',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      // extra structured fields
      'item_name': itemName,
      'quantity': currentStock,
      'unit': unit,
      'reorder_level': reorderLevel,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // OUT OF STOCK (treated as part of LOW STOCK REPORTS)
  // ─────────────────────────────────────────────────────────────
  static Future<void> noStock({
    required WidgetRef ref,
    required String itemName,
    required String unit,
  }) async {
    await _push(ref, {
      'category': 'low_stock',
      'title': 'Item Out of Stock',
      'message': '$itemName is now out of stock (0 $unit remaining).',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      // extra structured fields
      'item_name': itemName,
      'quantity': 0,
      'unit': unit,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // SUPPLIER ADDED
  // (rest of your existing methods below stay the same)
  // ─────────────────────────────────────────────────────────────
  static Future<void> supplierAdded({
    required WidgetRef ref,
    required String name,
  }) async {
    await _push(ref, {
      'category': 'Supplier added',
      'title': 'New Supplier Added',
      'message': 'Supplier $name was added.',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> supplierRemoved({
    required WidgetRef ref,
    required String name,
  }) async {
    await _push(ref, {
      'category': 'Supplier removed',
      'title': 'Supplier Removed',
      'message': 'Supplier $name was removed.',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
