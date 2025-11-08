import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsNotifier
    extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setTransactions(List<Map<String, dynamic>> transactions) =>
      state = transactions;

  void addTransaction(Map<String, dynamic> tx) {
    final next = [tx, ...state];
    next.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['occurred_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b['occurred_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    state = next;
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
          .select('id,type,quantity,note,occurred_at,item:items(id,name,unit)')
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
          })
          .select('id,type,quantity,note,occurred_at,item:items(id,name,unit)')
          .maybeSingle();
      if (insert == null) return null;
      return Map<String, dynamic>.from(insert as Map);
    } catch (_) {}
    return null;
  }
}

Future<void> refreshTransactions(WidgetRef ref) async {
  final items = await TransactionsRepository.listTransactions();
  ref.read(transactionsProvider.notifier).setTransactions(items);
}

Future<bool> logTransaction(
  WidgetRef ref, {
  required String itemId,
  required String type,
  required int quantity,
  String? note,
}) async {
  final tx = await TransactionsRepository.recordTransaction(
    itemId: itemId,
    type: type,
    quantity: quantity,
    note: note,
  );
  if (tx != null) {
    ref.read(transactionsProvider.notifier).addTransaction(tx);
    return true;
  }
  return false;
}
