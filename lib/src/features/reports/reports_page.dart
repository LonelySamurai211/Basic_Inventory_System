import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'grouped_reports_provider.dart';
import 'widgets/reports_tile.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reports & Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpandableSection(
            title: "STOCK IN REPORTS",
            icon: Icons.arrow_downward_rounded,
            iconColor: Colors.green,
            entries: grouped['stock_in']!,
          ),
          const SizedBox(height: 20),

          ExpandableSection(
            title: "STOCK OUT REPORTS",
            icon: Icons.arrow_upward_rounded,
            iconColor: Colors.red,
            entries: grouped['stock_out']!,
          ),
          const SizedBox(height: 20),

          ExpandableSection(
            title: "LOW STOCK REPORTS",
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            entries: grouped['low_stock']!,
          ),
          const SizedBox(height: 20),

          ExpandableSection(
            title: "NEW ITEM REPORTS",
            icon: Icons.new_releases_rounded,
            iconColor: Colors.blue,
            entries: grouped['new_item']!,
          ),
        ],
      ),
    );
  }
}

class ExpandableSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List entries;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.entries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(_sectionExpandedProvider(title));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                TextButton(
                  onPressed: () => ref
                      .read(_sectionExpandedProvider(title).notifier)
                      .state = !expanded,
                  child: Text(
                    expanded ? "Hide ▲" : "View ▼",
                    style: const TextStyle(fontSize: 14),
                  ),
                )
              ],
            ),
            if (expanded)
              Column(
                children: entries.map((e) => ReportTile(data: e)).toList(),
              )
          ],
        ),
      ),
    );
  }
}

final _sectionExpandedProvider =
    StateProvider.family<bool, String>((ref, key) => false);
