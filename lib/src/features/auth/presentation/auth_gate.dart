import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/app_shell.dart';
import '../domain/app_user.dart';
import 'auth_controller.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _showRegister = false;

  void _toggleView() {
    setState(() => _showRegister = !_showRegister);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.invalidate(authControllerProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (user) => _buildContent(context, user),
    );
  }

  Widget _buildContent(BuildContext context, AppUser? user) {
    if (user != null) {
      return AppShell(user: user);
    }

    if (_showRegister) {
      return RegisterPage(onToggleToLogin: _toggleView);
    }
    return LoginPage(onToggleToRegister: _toggleView);
  }
}
