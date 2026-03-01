import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/notifications_service.dart';
import '../../suppliers/suppliers_provider.dart';
import '../items_provider.dart';

Future<bool> showInventoryItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  Map<String, dynamic>? initialItem,
}) async {
  final isEditing = initialItem != null;
  final nameCtl = TextEditingController(
    text: initialItem?['name']?.toString() ?? '',
  );
  final descriptionCtl = TextEditingController(
    text: initialItem?['description']?.toString() ?? '',
  );
  final barcodeCtl = TextEditingController(
    text: initialItem?['barcode']?.toString() ?? '',
  );

  final suppliers = ref.read(suppliersListProvider);
  String? selectedSupplier =
      initialItem?['supplier_id']?.toString();
  String? foodSection =
      initialItem?['food_section']?.toString();
  String? selectedUnit =
      initialItem?['unit']?.toString() ?? 'pcs';

  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit item' : 'Add item'),
          content: SingleChildScrollView(
            child: _InventoryItemForm(
              nameCtl: nameCtl,
              descriptionCtl: descriptionCtl,
              barcodeCtl: barcodeCtl,
              suppliers: suppliers,
              selectedSupplier: selectedSupplier,
              onSupplierChanged: (value) =>
                  setState(() => selectedSupplier = value),
              foodSection: foodSection,
              onFoodSectionChanged: (value) =>
                  setState(() => foodSection = value),
              selectedUnit: selectedUnit,
              onUnitChanged: (value) =>
                  setState(() => selectedUnit = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!_validate(
                  nameCtl,
                  descriptionCtl,
                  barcodeCtl,
                  selectedSupplier,
                  foodSection,
                  messenger: scaffoldMessenger,
                )) {
                  return;
                }

                final name = nameCtl.text.trim();
                final description = descriptionCtl.text.trim().isEmpty
                    ? null
                    : descriptionCtl.text.trim();
                final barcode = barcodeCtl.text.trim().isEmpty
                    ? null
                    : barcodeCtl.text.trim();

                // prevent duplicate names
                final existingItems = ref.read(itemsListProvider);
                final normalizedNewName = name.toLowerCase();
                final currentId =
                    initialItem?['id']?.toString();

                final hasDuplicate = existingItems.any((it) {
                  final itemId = it['id']?.toString();
                  final itemName =
                      it['name']?.toString().trim().toLowerCase() ?? '';
                  if (isEditing && itemId == currentId) return false;
                  return itemName == normalizedNewName;
                });

                if (hasDuplicate) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'An item with this name already exists in the inventory.',
                      ),
                    ),
                  );
                  return;
                }

                final success = isEditing
                    ? await updateItemInProvider(
                        ref,
                        id: initialItem['id'] as String,
                        name: name,
                        unit: selectedUnit ?? 'pcs',
                        stock: null,
                        supplierId: selectedSupplier,
                        description: description,
                        barcode: barcode,
                        foodSection: foodSection,
                      )
                    : await createItem(
                        ref,
                        name: name,
                        unit: selectedUnit ?? 'pcs',
                        stock: 0,
                        supplierId: selectedSupplier,
                        description: description,
                        barcode: barcode,
                        foodSection: foodSection,
                      );

                if (!context.mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isEditing
                              ? 'Item updated'
                              : 'Item created')
                          : (isEditing
                              ? 'Failed to update item'
                              : 'Failed to create item'),
                    ),
                  ),
                );
                if (success) {
                  // Notification only for NEW items
                  if (!isEditing) {
                    String? supplierName;
                    if (selectedSupplier != null &&
                        selectedSupplier!.isNotEmpty) {
                      final match =
                          suppliers.cast<Map<String, dynamic>>().firstWhere(
                                (s) =>
                                    s['id']?.toString() ==
                                    selectedSupplier,
                                orElse: () => <String, dynamic>{},
                              );
                      supplierName =
                          match['name']?.toString();
                    }

                    await NotificationsService.itemAdded(
                      ref: ref,
                      itemName: name,
                      supplierName: supplierName,
                      unit: selectedUnit ?? 'pcs',
                    );
                  }
                  Navigator.pop(context, true);
                }
              },
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    ),
  );

  nameCtl.dispose();
  descriptionCtl.dispose();
  barcodeCtl.dispose();

  return result ?? false;
}

class _InventoryItemForm extends StatefulWidget {
  const _InventoryItemForm({
    required this.nameCtl,
    required this.descriptionCtl,
    required this.barcodeCtl,
    required this.suppliers,
    required this.selectedSupplier,
    required this.onSupplierChanged,
    required this.foodSection,
    required this.onFoodSectionChanged,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  final TextEditingController nameCtl;
  final TextEditingController descriptionCtl;
  final TextEditingController barcodeCtl;
  final List<Map<String, dynamic>> suppliers;
  final String? selectedSupplier;
  final ValueChanged<String?> onSupplierChanged;
  final String? foodSection;
  final ValueChanged<String?> onFoodSectionChanged;
  final String? selectedUnit;
  final ValueChanged<String?> onUnitChanged;

  @override
  State<_InventoryItemForm> createState() =>
      _InventoryItemFormState();
}

class _InventoryItemFormState extends State<_InventoryItemForm> {
  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;
    const minWidth = 360.0;
    const maxWidth = 720.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetWidth = math.min(maxWidth, screenWidth - 96);
    final formWidth = math.max(minWidth, targetWidth);
    final isWide = formWidth >= 560;
    final fieldWidth =
        isWide ? (formWidth - spacing) / 2 : formWidth;

    final normalizedFoodSection =
        (widget.foodSection?.isEmpty ?? true)
            ? null
            : widget.foodSection;
    final normalizedSupplier =
        (widget.selectedSupplier?.isEmpty ?? true)
            ? null
            : widget.selectedSupplier;

    final children = <Widget>[];

    void addField(Widget field, {bool spanFullWidth = false}) {
      children.add(
        SizedBox(
          width: spanFullWidth || !isWide ? formWidth : fieldWidth,
          child: field,
        ),
      );
    }

    addField(
      TextFormField(
        controller: widget.nameCtl,
        decoration:
            const InputDecoration(labelText: 'Item name'),
      ),
    );
    addField(
      TextFormField(
        controller: widget.descriptionCtl,
        decoration:
            const InputDecoration(labelText: 'Description'),
        maxLines: 2,
      ),
      spanFullWidth: true,
    );
    addField(
      TextFormField(
        controller: widget.barcodeCtl,
        decoration:
            const InputDecoration(labelText: 'Barcode'),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'[0-9A-Za-z-]'),
          ),
        ],
      ),
    );

    addField(
      DropdownButtonFormField<String?>(
        value: normalizedSupplier,
        decoration:
            const InputDecoration(labelText: 'Supplier'),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Select supplier'),
          ),
          ...widget.suppliers.map(
            (supplier) => DropdownMenuItem<String?>(
              value: supplier['id']?.toString(),
              child: Text(
                  supplier['name']?.toString() ?? 'Unknown'),
            ),
          ),
        ],
        onChanged: widget.onSupplierChanged,
      ),
    );

    addField(
      DropdownButtonFormField<String?>(
        value: normalizedFoodSection,
        decoration:
            const InputDecoration(labelText: 'Type of goods'),
        items: const [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('Select section'),
          ),
          DropdownMenuItem<String?>(
            value: 'wet',
            child: Text('Wet'),
          ),
          DropdownMenuItem<String?>(
            value: 'dry',
            child: Text('Dry'),
          ),
        ],
        onChanged: widget.onFoodSectionChanged,
      ),
    );

    addField(
      DropdownButtonFormField<String?>(
        value: widget.selectedUnit,
        decoration:
            const InputDecoration(labelText: 'Unit'),
        items: const [
          DropdownMenuItem<String?>(
            value: 'pcs',
            child: Text('pcs'),
          ),
          DropdownMenuItem<String?>(
            value: 'boxes',
            child: Text('boxes'),
          ),
          DropdownMenuItem<String?>(
            value: 'packs',
            child: Text('packs'),
          ),
        ],
        onChanged: widget.onUnitChanged,
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: formWidth,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children,
        ),
      ),
    );
  }
}

bool _validate(
  TextEditingController nameCtl,
  TextEditingController descriptionCtl,
  TextEditingController barcodeCtl,
  String? selectedSupplier,
  String? foodSection, {
  required ScaffoldMessengerState messenger,
}) {
  final missing = <String>[];

  void require(bool condition, String label) {
    if (!condition) missing.add(label);
  }

  require(nameCtl.text.trim().isNotEmpty, 'Item name');
  require(descriptionCtl.text.trim().isNotEmpty, 'Description');
  require(barcodeCtl.text.trim().isNotEmpty, 'Barcode');
  require((selectedSupplier ?? '').trim().isNotEmpty, 'Supplier');
  require((foodSection ?? '').trim().isNotEmpty, 'Type of goods');

  if (missing.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Complete the following fields: ${missing.join(', ')}',
        ),
      ),
    );
    return false;
  }
  return true;
}
