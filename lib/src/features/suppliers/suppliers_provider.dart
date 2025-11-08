import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class SuppliersListNotifier extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setSuppliers(List<Map<String, dynamic>> suppliers) => state = suppliers;

  void addSupplier(Map<String, dynamic> supplier) => state = [...state, supplier];
}

final suppliersListProvider =
    NotifierProvider<SuppliersListNotifier, List<Map<String, dynamic>>>(
        () => SuppliersListNotifier());

class SuppliersRepository {
  const SuppliersRepository._();

  static Future<List<Map<String, dynamic>>> listSuppliers() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('suppliers')
          .select('id,name,contact,address')
          .order('name');
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createSupplier({
    required String name,
    String? address,
    Map<String, dynamic>? contact,
  }) async {
    try {
      final client = Supabase.instance.client;
      final insert = await client.from('suppliers').insert({
        'name': name,
        'address': address,
        'contact': contact,
      }).select();
      return Map<String, dynamic>.from((insert as List).first as Map);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateSupplier({
    required String id,
    required String name,
    String? address,
    Map<String, dynamic>? contact,
  }) async {
    try {
      final client = Supabase.instance.client;
      final upd = await client
          .from('suppliers')
          .update({
            'name': name,
            'address': address,
            'contact': contact,
          })
          .eq('id', id)
          .select();
      return Map<String, dynamic>.from((upd as List).first as Map);
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteSupplier(String id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('suppliers').delete().eq('id', id);
      return true;
    } catch (_) {}
    return false;
  }
}

Future<void> refreshSuppliers(WidgetRef ref) async {
  final list = await SuppliersRepository.listSuppliers();
  ref.read(suppliersListProvider.notifier).setSuppliers(list);
}

Future<bool> createSupplierAndRefresh(
  WidgetRef ref, {
  required String name,
  String? address,
  Map<String, dynamic>? contact,
}) async {
  final created = await SuppliersRepository.createSupplier(
    name: name,
    address: address,
    contact: contact,
  );
  if (created != null) {
    ref.read(suppliersListProvider.notifier).addSupplier(created);
    return true;
  }
  return false;
}
