import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../data/auth_repository.dart';
import '../../domain/providers/auth_providers.dart';
import 'email_auth_screen.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    await action();
    final state = ref.read(authControllerProvider);
    if (state.hasError && context.mounted) {
      final error = state.error;
      final message =
          error is AuthFailure ? error.message : 'Something went wrong.';
      if (message == 'Sign-in cancelled.') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'HeroBid',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bid. Build. Battle.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 40),
                  GlassContainer(
                    child: Column(
                      children: [
                        NeonButton(
                          label: 'Continue with Google',
                          icon: Icons.g_mobiledata,
                          isLoading: isLoading,
                          onPressed: () => _handle(
                            context,
                            ref,
                            controller.signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        NeonButton(
                          label: 'Continue with Apple',
                          icon: Icons.apple,
                          isLoading: isLoading,
                          color: Colors.white,
                          onPressed: () => _handle(
                            context,
                            ref,
                            controller.signInWithApple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const EmailAuthScreen(),
                                      ),
                                    ),
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Continue with Email'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
}
