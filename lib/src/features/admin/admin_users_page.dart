import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/domain/app_user.dart';
import 'admin_user_service.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({required this.currentUser, super.key});

  final AppUser currentUser;

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  Future<void> _handleRefresh() {
    return ref.read(adminUsersProvider.notifier).refresh();
  }

  Future<void> _showCreateUserDialog() async {
    final result = await showDialog<_UserFormData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CreateUserDialog(),
    );

    if (result == null) return;

    final message = await ref
        .read(adminUsersProvider.notifier)
        .createUser(
          fullName: result.fullName,
          email: result.email,
          password: result.password,
          role: result.role,
          position: result.position,
          age: result.age,
          avatarBytes: result.avatarBytes,
          avatarExtension: result.avatarExtension,
        );
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User created successfully.')));
  }

  Future<void> _changeRole(AppUser user, String role) async {
    final message = await ref
        .read(adminUsersProvider.notifier)
        .changeRole(user: user, role: role);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Updated role for ${user.fullName}.')),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove user'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final message = await ref
        .read(adminUsersProvider.notifier)
        .deleteUser(user.id, currentUserId: widget.currentUser.id);

    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User removed.')));
  }

  Future<void> _pickAvatar(AppUser user) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    final extension = file.extension ?? 'png';
    final message = await ref
        .read(adminUsersProvider.notifier)
        .updateAvatar(user: user, data: bytes, fileExtension: extension);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Profile photo updated for ${user.fullName}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);
    return RefreshIndicator(
      onRefresh: _handleRefresh,
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
                      'Team directory',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Invite staff, manage roles, and keep access current.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Add member'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          usersState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _ErrorState(message: error.toString(), onRetry: _handleRefresh),
            data: (users) {
              if (users.isEmpty) {
                return const _EmptyState();
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            columnSpacing: 32,
                            headingRowHeight: 48,
                            dataRowMinHeight: 72,
                            columns: const [
                              DataColumn(label: Text('Member')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Position')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: [
                              for (final user in users)
                                DataRow(
                                  cells: [
                                    DataCell(_MemberCell(user: user)),
                                    DataCell(Text(user.email)),
                                    DataCell(
                                      _RoleSelector(
                                        user: user,
                                        onChangeRole: _changeRole,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        user.position?.isNotEmpty == true
                                            ? user.position!
                                            : '—',
                                      ),
                                    ),
                                    DataCell(
                                      _UserActions(
                                        user: user,
                                        isSelf:
                                            user.id == widget.currentUser.id,
                                        onDelete: _deleteUser,
                                        onUploadAvatar: _pickAvatar,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Could not load members',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_outlined),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Invite your first teammate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'New users can collaborate on inventory, purchasing, and reports.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCell extends StatelessWidget {
  const _MemberCell({required this.user});

  final AppUser user;

  String get _initials {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      if (part.isNotEmpty) {
        buffer.write(part[0].toUpperCase());
      }
    }
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            backgroundImage: user.avatarUrl?.isNotEmpty == true
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl?.isNotEmpty == true
                ? null
                : Text(
                    _initials,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.age != null)
                  Text(
                    '${user.age} yrs old',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.user, required this.onChangeRole});

  final AppUser user;
  final Future<void> Function(AppUser user, String role) onChangeRole;

  @override
  Widget build(BuildContext context) {
    final normalized = user.role.toLowerCase();
    final selectedValue = normalized == 'admin' ? 'admin' : 'staff';
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedValue,
        onChanged: (role) {
          if (role == null || role == selectedValue) return;
          onChangeRole(user, role);
        },
        items: const [
          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
          DropdownMenuItem(value: 'staff', child: Text('Staff')),
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.isSelf,
    required this.onDelete,
    required this.onUploadAvatar,
  });

  final AppUser user;
  final bool isSelf;
  final Future<void> Function(AppUser user) onDelete;
  final Future<void> Function(AppUser user) onUploadAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => onUploadAvatar(user),
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: 'Update profile photo',
          ),
          IconButton(
            onPressed: isSelf ? null : () => onDelete(user),
            icon: const Icon(Icons.delete_outline),
            tooltip: isSelf ? 'Cannot delete yourself' : 'Remove user',
          ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _positionController = TextEditingController();
  String _role = 'staff';
  int? _age;
  Uint8List? _avatarBytes;
  String? _avatarExtension;

  Future<void> _selectAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    setState(() {
      _avatarBytes = file.bytes;
      _avatarExtension = file.extension ?? 'png';
    });
  }

  void _clearAvatar() {
    setState(() {
      _avatarBytes = null;
      _avatarExtension = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite teammate'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : null,
                      child: _avatarBytes == null
                          ? const Icon(Icons.person_outline, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _selectAvatar,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _avatarBytes == null
                                ? 'Add photo'
                                : 'Replace photo',
                          ),
                        ),
                        if (_avatarBytes != null)
                          TextButton(
                            onPressed: _clearAvatar,
                            child: const Text('Remove photo'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.length < 6
                      ? 'Min 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrator'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _role = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Age (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() => _age = parsed);
                  },
                ),
              ],
            ),
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
              _UserFormData(
                fullName: _nameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                role: _role,
                position: _positionController.text.trim().isEmpty
                    ? null
                    : _positionController.text.trim(),
                age: _age,
                avatarBytes: _avatarBytes,
                avatarExtension: _avatarExtension,
              ),
            );
          },
          child: const Text('Create account'),
        ),
      ],
    );
  }
}

class _UserFormData {
  const _UserFormData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.position,
    this.age,
    this.avatarBytes,
    this.avatarExtension,
  });

  final String fullName;
  final String email;
  final String password;
  final String role;
  final String? position;
  final int? age;
  final Uint8List? avatarBytes;
  final String? avatarExtension;
}
