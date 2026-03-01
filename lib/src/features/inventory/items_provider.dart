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
          .select(
            'id,name,unit,stock_qty,supplier_id,description,'
            'barcode,food_section',
          )
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
    String? supplierId,
    String? description,
    String? barcode,
    String? foodSection,
    int? supplyLimit,
    int? reorderLevel,
  }) async {
    try {
      final client = Supabase.instance.client;
      final payload = {
        'name': name,
        'unit': unit,
        'stock_qty': stock,
        'supplier_id': supplierId,
        'description': description,
        'barcode': barcode,
        'food_section': foodSection,
      };
      print('Inserting item with payload: $payload');
      final insert = await client.from('items').insert(payload).select();
      print('Insert result: $insert');

      try {
        final first = (insert as List).first as Map;
        final item = Map<String, dynamic>.from(first);
        // Add local fields
        if (supplyLimit != null) item['supply_limit'] = supplyLimit;
        if (reorderLevel != null) item['reorder_level'] = reorderLevel;
        return item;
      } catch (e) {
        print('Error extracting first item: $e');
        return null;
      }
    } catch (e) {
      print('Error inserting item: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateItem({
    required String id,
    required String name,
    String? unit,
    int? stock,
    String? supplierId,
    String? description,
    String? barcode,
    String? foodSection,
    int? supplyLimit,
    int? reorderLevel,
  }) async {
    try {
      final client = Supabase.instance.client;
      final payload = <String, dynamic>{
        'name': name,
        'unit': unit,
        'supplier_id': supplierId,
      };
      if (stock != null) payload['stock_qty'] = stock;
      payload['description'] = description;
      payload['barcode'] = barcode;
      payload['food_section'] = foodSection;
      final upd = await client
          .from('items')
          .update(payload)
          .eq('id', id)
          .select();
      try {
        final first = (upd as List).first as Map;
        final item = Map<String, dynamic>.from(first);
        // Add local fields
        if (supplyLimit != null) item['supply_limit'] = supplyLimit;
        if (reorderLevel != null) item['reorder_level'] = reorderLevel;
        return item;
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
  final notifier = ref.read(itemsListProvider.notifier);
  final list = await ItemsRepository.listItems();
  notifier.setItems(list);
}

/// Utility to add an item and refresh provider
Future<bool> createItem(
  WidgetRef ref, {
  required String name,
  String? unit,
  int stock = 0,
  String? supplierId,
  String? description,
  String? barcode,
  String? foodSection,
  int? supplyLimit,
  int? reorderLevel,
}) async {
  final notifier = ref.read(itemsListProvider.notifier);
  final created = await ItemsRepository.addItem(
    name: name,
    unit: unit,
    stock: stock,
    supplierId: supplierId,
    description: description,
    barcode: barcode,
    foodSection: foodSection,
    supplyLimit: supplyLimit,
    reorderLevel: reorderLevel,
  );
  if (created != null) {
    notifier.addItem(created);
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
  String? supplierId,
  String? description,
  String? barcode,
  String? foodSection,
  int? supplyLimit,
  int? reorderLevel,
}) async {
  final notifier = ref.read(itemsListProvider.notifier);
  final updated = await ItemsRepository.updateItem(
    id: id,
    name: name,
    unit: unit,
    stock: stock,
    supplierId: supplierId,
    description: description,
    barcode: barcode,
    foodSection: foodSection,
    supplyLimit: supplyLimit,
    reorderLevel: reorderLevel,
  );
  if (updated != null) {
    notifier.updateItem(id, updated);
    return true;
  }
  return false;
}

Future<bool> deleteItemFromProvider(WidgetRef ref, String id) async {
  final notifier = ref.read(itemsListProvider.notifier);
  final ok = await ItemsRepository.deleteItem(id);
  if (ok) {
    notifier.removeItem(id);
    return true;
  }
  return false;
}
