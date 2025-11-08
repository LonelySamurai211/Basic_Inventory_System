import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemsListNotifier extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setItems(List<Map<String, dynamic>> items) => state = items;

  void addItem(Map<String, dynamic> item) => state = [...state, item];

  void updateItem(String id, Map<String, dynamic> updated) =>
      state = state.map((e) => e['id'] == id ? updated : e).toList();

  void removeItem(String id) =>
      state = state.where((e) => e['id'] != id).toList();
}

final itemsListProvider =
    NotifierProvider<ItemsListNotifier, List<Map<String, dynamic>>>(
      () => ItemsListNotifier(),
    );

class ItemsRepository {
  const ItemsRepository._();

  static Future<List<Map<String, dynamic>>> listItems() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('items')
          .select('id,name,unit,stock_qty,reorder_level,supplier_id')
          .order('name');

      // Supabase typically returns a List on a successful select. We'll attempt
      // to cast safely and fall back to an empty list on any type error.
      try {
        final list = (res as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return List<Map<String, dynamic>>.from(list);
      } catch (_) {
        return [];
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> addItem({
    required String name,
    String? unit,
    int stock = 0,
    int reorder = 0,
    String? supplierId,
  }) async {
    try {
      final client = Supabase.instance.client;
      final insert = await client.from('items').insert({
        'name': name,
        'unit': unit,
        'stock_qty': stock,
        'reorder_level': reorder,
        'supplier_id': supplierId,
      }).select();

      try {
        final first = (insert as List).first as Map;
        return Map<String, dynamic>.from(first);
      } catch (_) {
        return null;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateItem({
    required String id,
    required String name,
    String? unit,
    int? stock,
    int? reorder,
    String? supplierId,
  }) async {
    try {
      final client = Supabase.instance.client;
      final payload = <String, dynamic>{
        'name': name,
        'unit': unit,
        'supplier_id': supplierId,
      };
      if (stock != null) payload['stock_qty'] = stock;
      if (reorder != null) payload['reorder_level'] = reorder;
      final upd = await client
          .from('items')
          .update(payload)
          .eq('id', id)
          .select();
      try {
        final first = (upd as List).first as Map;
        return Map<String, dynamic>.from(first);
      } catch (_) {
        return null;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteItem(String id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('items').delete().eq('id', id);
      return true;
    } catch (_) {}
    return false;
  }
}

/// Utility to refresh the items provider
Future<void> refreshItems(WidgetRef ref) async {
  final list = await ItemsRepository.listItems();
  ref.read(itemsListProvider.notifier).setItems(list);
}

/// Utility to add an item and refresh provider
Future<bool> createItem(
  WidgetRef ref, {
  required String name,
  String? unit,
  int stock = 0,
  int reorder = 0,
  String? supplierId,
}) async {
  final created = await ItemsRepository.addItem(
    name: name,
    unit: unit,
    stock: stock,
    reorder: reorder,
    supplierId: supplierId,
  );
  if (created != null) {
    ref.read(itemsListProvider.notifier).addItem(created);
    return true;
  }
  return false;
}

Future<bool> updateItemInProvider(
  WidgetRef ref, {
  required String id,
  required String name,
  String? unit,
  int? stock,
  int? reorder,
  String? supplierId,
}) async {
  final updated = await ItemsRepository.updateItem(
    id: id,
    name: name,
    unit: unit,
    stock: stock,
    reorder: reorder,
    supplierId: supplierId,
  );
  if (updated != null) {
    ref.read(itemsListProvider.notifier).updateItem(id, updated);
    return true;
  }
  return false;
}

Future<bool> deleteItemFromProvider(WidgetRef ref, String id) async {
  final ok = await ItemsRepository.deleteItem(id);
  if (ok) {
    ref.read(itemsListProvider.notifier).removeItem(id);
    return true;
  }
  return false;
}
