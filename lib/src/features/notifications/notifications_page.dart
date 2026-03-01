import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifications_list_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),

      body: items.isEmpty
          ? const Center(child: Text('No notifications yet.'))
          : _buildGroupedList(context, items),
    );
  }
}

// --------------------------------------------------------
// GROUPED LIST BUILDER
// --------------------------------------------------------

Widget _buildGroupedList(
    BuildContext context, List<Map<String, dynamic>> items) {
  final groups = {
    'stock_in': <Map<String, dynamic>>[],
    'stock_out': <Map<String, dynamic>>[],
    'low_stock': <Map<String, dynamic>>[],
    'new_item': <Map<String, dynamic>>[],
    'others': <Map<String, dynamic>>[],
  };

  for (final n in items) {
    final cat = n['category']?.toString() ?? '';
    if (groups.containsKey(cat)) {
      groups[cat]!.add(n);
    } else {
      groups['others']!.add(n);
    }
  }

  return ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _Section(
        title: "Stock In Reports",
        icon: Icons.arrow_downward,
        items: groups['stock_in']!,
      ),
      const SizedBox(height: 20),

      _Section(
        title: "Stock Out Reports",
        icon: Icons.arrow_upward,
        items: groups['stock_out']!,
      ),
      const SizedBox(height: 20),

      _Section(
        title: "Low Stock Reports",
        icon: Icons.warning_amber_outlined,
        items: groups['low_stock']!,
      ),
      const SizedBox(height: 20),

      _Section(
        title: "New Item Reports",
        icon: Icons.fiber_new,
        items: groups['new_item']!,
      ),
      const SizedBox(height: 20),

      if (groups['others']!.isNotEmpty)
        _Section(
          title: "Other Notifications",
          icon: Icons.notifications,
          items: groups['others']!,
        ),
    ],
  );
}

// --------------------------------------------------------
// SECTION (VIEW / HIDE)
// --------------------------------------------------------

class _Section extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;

  const _Section({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, color: Colors.green.shade700),
            const SizedBox(width: 8),

            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const Spacer(),

            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? "Hide" : "View"),
            ),
          ],
        ),

        if (expanded) ...[
          const SizedBox(height: 8),
          for (final n in widget.items) _NotificationCard(n),
        ],
      ],
    );
  }
}

// --------------------------------------------------------
// EXPANDABLE NOTIFICATION CARD
// --------------------------------------------------------

class _NotificationCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const _NotificationCard(this.data);

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool showDetails = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final title = (data['title']?.toString().isNotEmpty ?? false)
        ? data['title'].toString()
        : "Notification";

    final message = (data['message'] ??
            data['description'] ??
            "No details available")
        .toString();

    final createdAt = DateTime.tryParse(data['created_at']?.toString() ?? "");

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => showDetails = !showDetails),
                  icon: Icon(
                    showDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),

            // Expanded details
            if (showDetails) ...[
              const SizedBox(height: 8),
              Text(message),

              const SizedBox(height: 8),

              if (createdAt != null)
                Text(
                  "Date: ${createdAt.toLocal().toString().split('T').first}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
