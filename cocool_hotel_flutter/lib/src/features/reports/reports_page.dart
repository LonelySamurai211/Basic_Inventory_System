import 'package:flutter/material.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Reports & Analytics',
            subtitle:
                'Generate consumption trends, supplier scorecards, and budget insights.',
          ),
          const SizedBox(height: 24),
          EmptyPlaceholder(
            title: 'No reports generated yet',
            message:
                'Build data-driven decisions by exporting PDF or Excel summaries.',
            icon: Icons.bar_chart_rounded,
            action: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.insert_chart_outlined_sharp),
              label: const Text('Create report'),
            ),
          ),
        ],
      ),
    );
  }
}
