import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class PurchaseOrdersPage extends StatelessWidget {
  const PurchaseOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Purchase Orders',
            subtitle: 'Record and review purchase orders (summary only).',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'No purchase orders yet',
            message:
                'You can record purchase orders here for reference; line-level details are not tracked.',
            icon: Icons.receipt_long_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Record purchase order'),
            ),
          ),
        ],
      ),
    );
  }
}
