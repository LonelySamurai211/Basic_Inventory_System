import 'package:flutter/services.dart';

/// Centralized validation helpers for supplier forms.
class SupplierValidators {
  static final RegExp _namePattern = RegExp(r'^[A-Za-z ]+$');
  static final RegExp _tinPattern = RegExp(r'^\d{3}-\d{3}-\d{3}-\d{3}$');
  static final RegExp _mobilePattern = RegExp(r'^\d{11}$');
  static final RegExp _telephonePattern = RegExp(r'^\d{7}$');
  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@(gmail|yahoo)\.com$', caseSensitive: false);

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    if (!_namePattern.hasMatch(trimmed)) {
      return 'Letters only (A-Za-z)';
    }
    return null;
  }

  static String? taxId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    if (!_tinPattern.hasMatch(trimmed)) {
      return 'Format: 111-222-333-444';
    }
    return null;
  }

  static String? contactNumber(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    if (!_mobilePattern.hasMatch(trimmed) &&
        !_telephonePattern.hasMatch(trimmed)) {
      return 'Use 11-digit mobile or 7-digit telephone';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Only gmail.com or yahoo.com emails';
    }
    return null;
  }

  static String? address(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class SupplierInputFormatters {
  static final TextInputFormatter lettersOnly =
      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]'));
  static final TextInputFormatter taxId =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'));
  static final TextInputFormatter digitsOnly =
      FilteringTextInputFormatter.digitsOnly;
}
