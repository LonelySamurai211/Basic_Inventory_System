import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      _DashboardStat(
        label: 'Total Stock Value',
        value: '₱ 845,200',
        icon: Icons.inventory_2_outlined,
        caption: 'Across 186 active items',
        trendLabel: '+6.2% vs last month',
        trendPositive: true,
      ),
      _DashboardStat(
        label: 'Low-stock Alerts',
        value: '14',
        icon: Icons.warning_amber_rounded,
        caption: 'Reorder within 3 days',
        trendLabel: '+2 new this week',
        trendPositive: false,
      ),
      _DashboardStat(
        label: 'Pending Requests',
        value: '5',
        icon: Icons.assignment_outlined,
        caption: 'Awaiting approval',
        trendLabel: '4 resolved last week',
        trendPositive: true,
      ),
      _DashboardStat(
        label: 'Receipts Today',
        value: '9',
        icon: Icons.local_shipping_outlined,
        caption: 'Average processing 1h 12m',
        trendLabel: 'On track',
        trendPositive: true,
      ),
    ];

    final shortCuts = [
      _Shortcut(
        label: 'New Purchase Order',
        icon: Icons.note_add_outlined,
        color: AppColors.forest,
      ),
      _Shortcut(
        label: 'Receive Delivery',
        icon: Icons.move_to_inbox_outlined,
        color: AppColors.accent,
      ),
      _Shortcut(
        label: 'Log Consumption',
        icon: Icons.playlist_add_check_outlined,
        color: AppColors.fern,
      ),
      _Shortcut(
        label: 'View Alerts',
        icon: Icons.notifications_active_outlined,
        color: AppColors.warning,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good day, team', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Monitor hotel supplies, approvals, and movements at a glance.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          _buildStatsGrid(stats),
          const SizedBox(height: 40),
          SectionHeader(
            title: 'Quick Actions',
            subtitle: 'Streamline daily routines with ready-to-run workflows.',
            trailing: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Customize'),
            ),
          ),
          const SizedBox(height: 16),
          _buildShortcutRow(shortCuts),
          const SizedBox(height: 40),
          SectionHeader(
            title: 'Procurement Pipeline',
            subtitle: 'Track requests from submission to fulfillment.',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 16),
          _buildProcurementTable(theme),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<_DashboardStat> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return StatCard(
              label: stat.label,
              value: stat.value,
              icon: stat.icon,
              caption: stat.caption,
              trendLabel: stat.trendLabel,
              trendPositive: stat.trendPositive,
            );
          },
        );
      },
    );
  }

  Widget _buildShortcutRow(List<_Shortcut> shortcuts) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: shortcuts
          .map((shortcut) => _ShortcutCard(shortcut: shortcut))
          .toList(),
    );
  }

  Widget _buildProcurementTable(ThemeData theme) {
    final rows = [
      (
        po: 'PO-2025-0081',
        department: 'Housekeeping',
        status: 'Awaiting approval',
        eta: 'Due in 2 days',
      ),
      (
        po: 'PO-2025-0078',
        department: 'Kitchen',
        status: 'Pending delivery',
        eta: 'Eta 30 Oct',
      ),
      (
        po: 'PO-2025-0075',
        department: 'Engineering',
        status: 'Partially fulfilled',
        eta: 'Follow up supplier',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Purchase Orders',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Export report'),
                ),
              ],
            ),
            const Divider(height: 32),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(row.po, style: theme.textTheme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.department,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(flex: 2, child: _StatusBadge(text: row.status)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          row.eta,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.shortcut});

  final _Shortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shortcut.color.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B6E4F),
            blurRadius: 16,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: shortcut.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(shortcut.icon, color: shortcut.color),
          ),
          const SizedBox(height: 16),
          Text(shortcut.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('Open')),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _DashboardStat {
  const _DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
    required this.trendLabel,
    required this.trendPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final String caption;
  final String trendLabel;
  final bool trendPositive;
}
