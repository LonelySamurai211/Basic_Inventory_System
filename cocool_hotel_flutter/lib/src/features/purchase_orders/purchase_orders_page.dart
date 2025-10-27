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
            subtitle: 'Review departmental requests and oversee fulfillment.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'No purchase orders yet',
            message:
                'Create requests to replenish low stock and route approvals to department heads.',
            icon: Icons.receipt_long_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Raise purchase order'),
            ),
          ),
        ],
      ),
    );
  }
}
