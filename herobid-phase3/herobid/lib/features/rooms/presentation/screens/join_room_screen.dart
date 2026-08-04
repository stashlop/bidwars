import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/providers/room_providers.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final roomId =
          await ref.read(roomControllerProvider.notifier).joinRoom(_ctrl.text.trim());
      if (!mounted) return;
      context.go('/lobby/$roomId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(roomControllerProvider);
    final isLoading = ctrl.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'JOIN ROOM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: _glow(cs.secondary, 340),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _glow(cs.primary, 260),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Hero icon
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.secondary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.login_rounded,
                          size: 48,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Enter Room Code',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask the room host for the 6-character code.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white38),
                    ),
                    const SizedBox(height: 28),
                    // Code input
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: TextFormField(
                          controller: _ctrl,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '······',
                            hintStyle: TextStyle(
                              color: Colors.white12,
                              fontSize: 28,
                              letterSpacing: 8,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: cs.primary.withOpacity(0.7),
                                  width: 1.5),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Enter the full 6-character code.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _join(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _join,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.secondary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Text(
                                'JOIN ROOM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(0.15), Colors.transparent]),
        ),
      );
}
