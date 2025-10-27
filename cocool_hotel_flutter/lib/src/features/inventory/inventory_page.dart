import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Inventory Catalog',
            subtitle:
                'Maintain stock levels, categories, and supplier assignments.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'No items yet',
            message:
                'Start by adding materials or importing your existing catalog.',
            icon: Icons.inventory_2_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Add inventory item'),
            ),
          ),
        ],
      ),
    );
  }
}
