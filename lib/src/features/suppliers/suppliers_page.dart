import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_placeholder.dart';
import '../../widgets/section_header.dart';
import '../notifications/notifications_service.dart';
import 'supplier_validators.dart';
import 'suppliers_provider.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      // Load suppliers the first time the page is shown.
      refreshSuppliers(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Supplier Directory',
            subtitle:
                'Track vendors and keep contact information within reach.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () {
                _showCreateDialog();
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Add supplier'),
            ),
          ),
          const SizedBox(height: 24),
          if (suppliers.isEmpty)
            EmptyPlaceholder(
              title: 'No suppliers yet',
              message: 'Log each vendor so your team knows who to contact.',
              icon: Icons.store_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 320.0;
                const spacing = 16.0;
                final maxWidth = constraints.maxWidth;
                final computedColumns = maxWidth <= minCardWidth
                    ? 1
                    : (maxWidth / minCardWidth).floor();
                final columns = computedColumns < 1
                    ? 1
                    : (computedColumns > 4 ? 4 : computedColumns);
                final cardWidth = columns == 1
                    ? maxWidth
                    : (maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final supplier in suppliers)
                      SizedBox(
                        width: cardWidth,
                        child: _SupplierCard(
                          supplier: supplier,
                          onEdit: () {
                            _showEditDialog(supplier);
                          },
                          onDelete: () {
                            _deleteSupplier(supplier);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Map<String, dynamic> supplier) async {
    final messenger = ScaffoldMessenger.of(context);
    final id = supplier['id']?.toString();
    if (id == null) return;
    final ok = await SuppliersRepository.deleteSupplier(id);
    if (!mounted) return;

    if (ok) {
      await refreshSuppliers(ref);
      await NotificationsService.supplierRemoved(
        ref: ref,
        name: supplier['name']?.toString() ?? 'Supplier',
      );
      messenger.showSnackBar(const SnackBar(content: Text('Supplier deleted')));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete supplier')),
      );
    }
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final taxIdCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final addrCtl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create supplier'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  inputFormatters: [SupplierInputFormatters.lettersOnly],
                  validator: SupplierValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taxIdCtl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Identification Number',
                    hintText: 'Example: 123-456-789-000',
                  ),
                  inputFormatters: [SupplierInputFormatters.taxId],
                  validator: SupplierValidators.taxId,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtl,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    helperText: '11-digit mobile or 7-digit telephone',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [SupplierInputFormatters.digitsOnly],
                  validator: SupplierValidators.contactNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtl,
                  decoration: const InputDecoration(
                    labelText: 'Contact email address',
                    helperText: 'Only gmail.com or yahoo.com domains',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: SupplierValidators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  minLines: 2,
                  maxLines: 3,
                  validator: SupplierValidators.address,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await createSupplierAndRefresh(
                ref,
                name: nameCtl.text.trim(),
                taxId: taxIdCtl.text.trim(),
                contactNumber: phoneCtl.text.trim(),
                contactEmail: emailCtl.text.trim().toLowerCase(),
                address: addrCtl.text.trim(),
              );
              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Supplier created' : 'Failed to create supplier',
                  ),
                ),
              );
              if (ok && navigator.canPop()) {
                navigator.pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> supplier) {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController(
      text: supplier['name']?.toString() ?? '',
    );
    final taxIdCtl = TextEditingController(
      text: supplier['tax_id']?.toString() ??
          supplier['contact']?['taxId']?.toString() ??
          '',
    );
    final phoneCtl = TextEditingController(
      text: supplier['contact_number']?.toString() ??
          supplier['contact']?['phone']?.toString() ??
          '',
    );
    final emailCtl = TextEditingController(
      text: supplier['contact_email']?.toString() ??
          supplier['contact']?['email']?.toString() ??
          '',
    );
    final addrCtl = TextEditingController(
      text: supplier['address']?.toString() ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit supplier'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  inputFormatters: [SupplierInputFormatters.lettersOnly],
                  validator: SupplierValidators.name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taxIdCtl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Identification Number',
                  ),
                  inputFormatters: [SupplierInputFormatters.taxId],
                  validator: SupplierValidators.taxId,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtl,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    helperText: '11-digit mobile or 7-digit telephone',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [SupplierInputFormatters.digitsOnly],
                  validator: SupplierValidators.contactNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtl,
                  decoration: const InputDecoration(
                    labelText: 'Contact email address',
                    helperText: 'Only gmail.com or yahoo.com domains',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: SupplierValidators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  minLines: 2,
                  maxLines: 3,
                  validator: SupplierValidators.address,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final updated = await SuppliersRepository.updateSupplier(
                id: supplier['id'] as String,
                name: nameCtl.text.trim(),
                taxId: taxIdCtl.text.trim(),
                contactNumber: phoneCtl.text.trim(),
                contactEmail: emailCtl.text.trim().toLowerCase(),
                address: addrCtl.text.trim(),
              );
              if (!mounted) return;

              if (updated != null) {
                await refreshSuppliers(ref);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Supplier updated')),
                );
                if (navigator.canPop()) {
                  navigator.pop();
                }
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to update supplier')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final legacyContact = supplier['contact'];
    final taxId = supplier['tax_id']?.toString() ??
      (legacyContact is Map ? legacyContact['taxId']?.toString() : null) ??
      '';
    final contactEmail = supplier['contact_email']?.toString() ??
      (legacyContact is Map ? legacyContact['email']?.toString() : null) ??
      '';
    final phone = supplier['contact_number']?.toString() ??
      (legacyContact is Map ? legacyContact['phone']?.toString() : null) ??
      '';
    final address = supplier['address']?.toString() ?? '';
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    supplier['name']?.toString() ?? 'Unnamed supplier',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (taxId.isNotEmpty)
                  _SupplierInfoPill(
                    icon: Icons.badge_outlined,
                    label: 'TIN: $taxId',
                  ),
                if (contactEmail.isNotEmpty)
                  _SupplierInfoPill(
                    icon: Icons.mail_outline,
                    label: contactEmail,
                  ),
                _SupplierInfoPill(
                  icon: Icons.phone_enabled_outlined,
                  label: phone.isEmpty ? 'No contact number' : phone,
                ),
                _SupplierInfoPill(
                  icon: Icons.location_on_outlined,
                  label: address.isEmpty ? 'No address provided' : address,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierInfoPill extends StatelessWidget {
  const _SupplierInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
