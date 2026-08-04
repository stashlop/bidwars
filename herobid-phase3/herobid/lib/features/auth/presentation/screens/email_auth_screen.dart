import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../data/auth_repository.dart';
import '../../domain/providers/auth_providers.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);

    if (_isSignUp) {
      await controller.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );
    } else {
      await controller.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    final state = ref.read(authControllerProvider);
    if (state.hasError && mounted) {
      final error = state.error;
      final message =
          error is AuthFailure ? error.message : 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      final error = state.error;
      final message =
          error is AuthFailure ? error.message : 'Something went wrong.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create account' : 'Sign in'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Hero name'),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'At least 3 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  NeonButton(
                    label: _isSignUp ? 'Create account' : 'Sign in',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
