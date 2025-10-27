import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Transaction Log',
            subtitle: 'Trace every issuance, receipt, and adjustment.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'No movements recorded yet',
            message:
                'Track accountability by logging stock in/out as they happen.',
            icon: Icons.compare_arrows_outlined,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.playlist_add_outlined),
              label: const Text('Log transaction'),
            ),
          ),
        ],
      ),
    );
  }
}
