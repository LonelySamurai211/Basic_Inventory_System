import 'package:flutter/material.dart';

import '../../widgets/section_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Workspace Settings',
            subtitle: 'Manage hotel profile, roles, and integrations.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Branding', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Upload logo, set accent colors, and update company information.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Upload logo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Configure backup frequency, session policies, and access control.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.security_outlined),
                    label: const Text('Open security settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
