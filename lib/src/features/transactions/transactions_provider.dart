import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notifications/notifications_service.dart';
import '../suppliers/suppliers_provider.dart';

class TransactionsNotifier
    extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setTransactions(List<Map<String, dynamic>> transactions) =>
      state = transactions;

  void addTransaction(Map<String, dynamic> tx) {
    final next = [tx, ...state];
    next.sort((a, b) {
      final aDate = _parseSortDate(a);
      final bDate = _parseSortDate(b);
      return bDate.compareTo(aDate);
    });
    state = next;
  }

  void removeTransaction(String transactionId) {
    state = state.where((tx) => tx['id']?.toString() != transactionId).toList();
  }

  DateTime _parseSortDate(Map<String, dynamic> payload) {
    final dateString = payload['transaction_date']?.toString();
    final parsedDate = DateTime.tryParse(dateString ?? '');
    if (parsedDate != null) {
      return parsedDate;
    }
    final occurred = DateTime.tryParse(payload['occurred_at']?.toString() ?? '');
    return occurred ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Map<String, dynamic>>>(
  () => TransactionsNotifier(),
);

class TransactionsRepository {
  const TransactionsRepository._();

  static Future<List<Map<String, dynamic>>> listTransactions() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('transactions')
          .select(
            'id,item_id,type,quantity,note,occurred_at,transaction_date,'
            'supplier_id,manufactured_on,delivered_on,expiry_on,'
            'item:items(id,name,unit,supplier_id)',
          )
          .order('transaction_date', ascending: false)
          .order('occurred_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> recordTransaction({
    required String itemId,
    required String type,
    required int quantity,
    String? note,
    required DateTime transactionDate,
    String? supplierId,
    DateTime? manufacturedOn,
    required DateTime deliveredOn,
    DateTime? expiryOn,
  }) async {
    try {
      final client = Supabase.instance.client;
      final insert = await client
          .from('transactions')
          .insert({
            'item_id': itemId,
            'type': type,
            'quantity': quantity,
            'note': note,
            'transaction_date': _isoDate(transactionDate),
            'supplier_id': supplierId,
            'manufactured_on': _isoDate(manufacturedOn),
            'delivered_on': _isoDate(deliveredOn),
            'expiry_on': _isoDate(expiryOn),
          })
          .select(
            'id,item_id,type,quantity,note,occurred_at,transaction_date,'
            'supplier_id,manufactured_on,delivered_on,expiry_on,'
            'item:items(id,name,unit,supplier_id)',
          )
          .maybeSingle();
      if (insert == null) return null;
      return Map<String, dynamic>.from(insert as Map);
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      final client = Supabase.instance.client;
      await client.from('transactions').delete().eq('id', transactionId);
      return true;
    } catch (_) {}
    return false;
  }
}

Future<void> refreshTransactions(WidgetRef ref) async {
  final notifier = ref.read(transactionsProvider.notifier);
  final items = await TransactionsRepository.listTransactions();
  notifier.setTransactions(items);
}

Future<bool> logTransaction(
  WidgetRef ref, {
  required String itemId,
  required String type,
  required int quantity,
  DateTime? transactionDate,
  String? note,
  String? supplierId,
  DateTime? manufacturedOn,
  DateTime? deliveredOn,
  DateTime? expiryOn,
}) async {
  final now = DateTime.now();
  final effectiveTransactionDate = transactionDate ?? now;
  final effectiveDeliveryDate = deliveredOn ?? now;
  final notifier = ref.read(transactionsProvider.notifier);

  final tx = await TransactionsRepository.recordTransaction(
    itemId: itemId,
    type: type,
    quantity: quantity,
    note: note,
    transactionDate: effectiveTransactionDate,
    supplierId: supplierId,
    manufacturedOn: manufacturedOn,
    deliveredOn: effectiveDeliveryDate,
    expiryOn: expiryOn,
  );

  if (tx != null) {
    notifier.addTransaction(tx);

    // 🔔 Create notification for this stock movement
    await NotificationsService.stockMovement(
      ref: ref,
      type: tx['type']?.toString() ?? type,
      quantity: _coerceInt(tx['quantity']) ?? quantity,
      itemName: _extractItemName(tx) ?? 'Unknown item',
      supplierName: _extractSupplierName(ref, tx),
      unit: _extractItemUnit(tx) ?? 'pcs',
      transactionDate:
          _coerceDate(tx['transaction_date']) ??
          _coerceDate(tx['occurred_at']) ??
          effectiveTransactionDate,
    );

    return true;
  }
  return false;
}

int? _coerceInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _coerceDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _extractItemName(Map<String, dynamic> tx) {
  final item = tx['item'];
  if (item is Map && item['name'] != null) {
    return item['name'].toString();
  }
  return null;
}

String? _extractItemUnit(Map<String, dynamic> tx) {
  final item = tx['item'];
  if (item is Map && item['unit'] != null) {
    return item['unit'].toString();
  }
  return null;
}

String? _extractSupplierName(WidgetRef ref, Map<String, dynamic> tx) {
  final suppliers = ref.read(suppliersListProvider);

  // Prefer explicit supplier_id on the transaction; fall back to item's supplier_id
  final txSupplierId = tx['supplier_id']?.toString();
  final item = tx['item'];
  final itemSupplierId =
      item is Map ? item['supplier_id']?.toString() : null;

  final supplierId = txSupplierId ?? itemSupplierId;
  if (supplierId == null) return null;

  final match = suppliers.cast<Map<String, dynamic>>().firstWhere(
        (s) => s['id']?.toString() == supplierId,
        orElse: () => <String, dynamic>{},
      );
  return match['name']?.toString();
}

String? _isoDate(DateTime? value) =>
    value != null ? value.toIso8601String().substring(0, 10) : null;

Future<bool> deleteTransaction(WidgetRef ref, String transactionId) async {
  final notifier = ref.read(transactionsProvider.notifier);
  final success = await TransactionsRepository.deleteTransaction(transactionId);
  if (success) {
    notifier.removeTransaction(transactionId);
  }
  return success;
}
