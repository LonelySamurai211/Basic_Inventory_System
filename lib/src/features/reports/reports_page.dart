import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/app_user.dart';
import 'data/reports_repository.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _refresh();
  }

  Future<void> _refresh() => refreshReports(ref);

  Future<void> _createReport() async {
    final result = await showDialog<_ReportDraft>(
      context: context,
      builder: (context) => const _NewReportDialog(),
    );

    if (result == null) return;

    final created = await ReportsRepository.createReport(
      title: result.title,
      summary: result.summary,
      details: result.details,
      userId: widget.user.id,
    );

    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save report. Try again later.')),
      );
      return;
    }
    ref.read(reportsProvider.notifier).addReport(created);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Generate consumption trends, supplier scorecards, and budget insights.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _createReport,
                icon: const Icon(Icons.insert_chart_outlined_sharp),
                label: const Text('Create report'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (reports.isEmpty)
            const _EmptyReports()
          else
            ...reports.map((report) => _ReportCard(report: report)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = DateTime.tryParse(report['created_at']?.toString() ?? '');
    final creator = report['creator'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report['title']?.toString() ?? 'Untitled report',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if ((report['summary']?.toString() ?? '').isNotEmpty)
              Text(
                report['summary'].toString(),
                style: theme.textTheme.bodyMedium,
              ),
            if ((report['details']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                report['details'].toString(),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    _initials(creator?['full_name']?.toString()),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator?['full_name']?.toString() ?? 'Team member',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      createdAt != null
                          ? MaterialLocalizations.of(context)
                              .formatShortDate(createdAt)
                          : 'Unknown date',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Export (coming soon)',
                  icon: const Icon(Icons.file_download_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No reports generated yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Build data-driven decisions by exporting PDF or Excel summaries.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewReportDialog extends StatefulWidget {
  const _NewReportDialog();

  @override
  State<_NewReportDialog> createState() => _NewReportDialogState();
}

class _NewReportDialogState extends State<_NewReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create report'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Report title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration:
                    const InputDecoration(labelText: 'Executive summary'),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              _ReportDraft(
                title: _titleController.text.trim(),
                summary: _summaryController.text.trim().isEmpty
                    ? null
                    : _summaryController.text.trim(),
                details: _detailsController.text.trim().isEmpty
                    ? null
                    : _detailsController.text.trim(),
              ),
            );
          },
          child: const Text('Save report'),
        ),
      ],
    );
  }
}

class _ReportDraft {
  const _ReportDraft({
    required this.title,
    this.summary,
    this.details,
  });

  final String title;
  final String? summary;
  final String? details;
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) {
    return 'TM';
  }
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final buffer = StringBuffer();
  for (final part in parts) {
    if (buffer.length >= 2) break;
    final iterator = part.runes.iterator;
    if (iterator.moveNext()) {
      buffer.write(String.fromCharCode(iterator.current).toUpperCase());
    }
  }
  return buffer.isEmpty ? 'TM' : buffer.toString();
}
