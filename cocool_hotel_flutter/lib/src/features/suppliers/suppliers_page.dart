import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Supplier Directory',
            subtitle:
                'Centralize vendor contacts, lead times, and contract details.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'Add your first supplier',
            message:
                'Keep delivery performance and contacts close at hand.',
            icon: Icons.storefront_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create supplier profile'),
            ),
          ),
        ],
      ),
    );
  }
}
