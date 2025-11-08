import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsNotifier extends riverpod.Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void setReports(List<Map<String, dynamic>> reports) => state = reports;

  void addReport(Map<String, dynamic> report) => state = [report, ...state];
}

final reportsProvider =
    NotifierProvider<ReportsNotifier, List<Map<String, dynamic>>>(
  ReportsNotifier.new,
);

class ReportsRepository {
  ReportsRepository._();

  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> fetchReports() async {
    try {
      final res = await _client
          .from('reports')
          .select('id,title,summary,details,created_at,creator:app_users(id,full_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(
        (res as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createReport({
    required String title,
    String? summary,
    String? details,
    String? userId,
  }) async {
    try {
      final insert = await _client
          .from('reports')
          .insert({
            'title': title,
            'summary': summary,
            'details': details,
            'created_by': userId,
          })
          .select('id,title,summary,details,created_at,creator:app_users(id,full_name)')
          .maybeSingle();
      if (insert == null) return null;
      return Map<String, dynamic>.from(insert as Map);
    } catch (_) {
      return null;
    }
  }
}

Future<void> refreshReports(WidgetRef ref) async {
  final list = await ReportsRepository.fetchReports();
  ref.read(reportsProvider.notifier).setReports(list);
}
