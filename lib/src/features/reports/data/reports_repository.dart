import '../../notifications/data/notifications_repository.dart';

class ReportsRepository {
  const ReportsRepository._();

  static Future<Map<String, List<Map<String, dynamic>>>> fetchGroupedReports() async {
    final notifications = await NotificationsRepository.fetchNotifications();

    final stockIn = <Map<String, dynamic>>[];
    final stockOut = <Map<String, dynamic>>[];
    final lowStock = <Map<String, dynamic>>[];
    final newItem = <Map<String, dynamic>>[];

    for (final n in notifications) {
      final cat = (n['category'] ?? '').toString().toLowerCase();

      switch (cat) {
        case 'stock_in':
          stockIn.add(n);
          break;
        case 'stock_out':
          stockOut.add(n);
          break;
        case 'low_stock':
        case 'no_stock':
          lowStock.add(n);
          break;
        case 'new_item':
          newItem.add(n);
          break;
      }
    }

    return {
      'stock_in': stockIn,
      'stock_out': stockOut,
      'low_stock': lowStock,
      'new_item': newItem,
    };
  }
}
