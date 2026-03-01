import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notifications/notifications_service.dart';

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
          .select('id,name,tax_id,contact_number,contact_email,address')
          .order('name');
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createSupplier({
    required String name,
    required String taxId,
    required String contactNumber,
    required String contactEmail,
    required String address,
  }) async {
    try {
      final client = Supabase.instance.client;
      final insert = await client.from('suppliers').insert({
        'name': _normalize(name),
        'tax_id': _normalize(taxId),
        'contact_number': _normalize(contactNumber),
        'contact_email': _normalize(contactEmail),
        'address': _normalize(address),
      }).select();
      return Map<String, dynamic>.from((insert as List).first as Map);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateSupplier({
    required String id,
    required String name,
    required String taxId,
    required String contactNumber,
    required String contactEmail,
    required String address,
  }) async {
    try {
      final client = Supabase.instance.client;
      final upd = await client
          .from('suppliers')
          .update({
            'name': _normalize(name),
            'tax_id': _normalize(taxId),
            'contact_number': _normalize(contactNumber),
            'contact_email': _normalize(contactEmail),
            'address': _normalize(address),
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
  final notifier = ref.read(suppliersListProvider.notifier);
  final list = await SuppliersRepository.listSuppliers();
  notifier.setSuppliers(list);
}

Future<bool> createSupplierAndRefresh(
  WidgetRef ref, {
  required String name,
  required String taxId,
  required String contactNumber,
  required String contactEmail,
  required String address,
}) async {
  final notifier = ref.read(suppliersListProvider.notifier);
  final created = await SuppliersRepository.createSupplier(
    name: name,
    taxId: taxId,
    contactNumber: contactNumber,
    contactEmail: contactEmail,
    address: address,
  );
  if (created != null) {
    notifier.addSupplier(created);
    await NotificationsService.supplierAdded(
      ref: ref,
      name: created['name']?.toString() ?? name,
    );
    return true;
  }
  return false;
}

String _normalize(String value) => value.trim();
