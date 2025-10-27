import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Alerts & Notifications',
            subtitle: 'Stay ahead of low-stock, expiries, and workflow updates.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'All clear',
            message:
                'Alerts will appear here and in the system tray when triggered.',
            icon: Icons.notifications_active_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configure rules'),
            ),
          ),
        ],
      ),
    );
  }
}
