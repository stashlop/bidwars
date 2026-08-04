import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/providers/auth_providers.dart';
import '../../../domain/providers/room_providers.dart';

// Default character pool options displayed to the host
const _kPools = {
  'Marvel': [
    'iron_man', 'captain_america', 'thor', 'hulk', 'spider_man',
    'black_widow', 'hawkeye', 'doctor_strange', 'black_panther', 'scarlet_witch',
  ],
  'DC': [
    'superman', 'batman', 'wonder_woman', 'the_flash', 'aquaman',
    'green_lantern', 'cyborg', 'shazam', 'green_arrow', 'martian_manhunter',
  ],
  'Anime': [
    'goku', 'naruto', 'luffy', 'ichigo', 'saitama',
    'vegeta', 'sasuke', 'zoro', 'eren', 'all_might',
  ],
  'Movie': [
    'john_wick', 'neo', 'terminator', 'gandalf', 'dumbledore',
    'predator', 'ripley', 'morpheus', 'maximus', 'jack_sparrow',
  ],
};

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  int _budget = 1000;
  int _maxPlayers = 4;
  final Set<String> _selectedPools = {'Marvel'};

  List<String> get _characterPool => _kPools.entries
      .where((e) => _selectedPools.contains(e.key))
      .expand((e) => e.value)
      .toList();

  Future<void> _create() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    if (_selectedPools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one character universe.'),
      ));
      return;
    }
    try {
      final result = await ref.read(roomControllerProvider.notifier).createRoom(
            budget: _budget,
            maxPlayers: _maxPlayers,
            characterPool: _characterPool,
          );
      if (!mounted) return;
      context.go('/lobby/${result['roomId']}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
          'CREATE ROOM',
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
          // Ambient glow
          Positioned(
            top: -120,
            left: -80,
            child: _glow(cs.primary, 350),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: _glow(cs.secondary, 280),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(context, 'STARTING BUDGET'),
                  const SizedBox(height: 8),
                  _BudgetSelector(
                    value: _budget,
                    onChanged: (v) => setState(() => _budget = v),
                  ),
                  const SizedBox(height: 28),
                  _section(context, 'MAX PLAYERS'),
                  const SizedBox(height: 8),
                  _PlayerCountSelector(
                    value: _maxPlayers,
                    onChanged: (v) => setState(() => _maxPlayers = v),
                  ),
                  const SizedBox(height: 28),
                  _section(context, 'CHARACTER UNIVERSES'),
                  const SizedBox(height: 4),
                  Text(
                    'Characters from selected universes will be auctioned.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white38),
                  ),
                  const SizedBox(height: 12),
                  ..._kPools.keys.map((universe) => _UniverseTile(
                        label: universe,
                        selected: _selectedPools.contains(universe),
                        onToggle: (v) {
                          setState(() {
                            if (v) {
                              _selectedPools.add(universe);
                            } else {
                              _selectedPools.remove(universe);
                            }
                          });
                        },
                      )),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome_mosaic_outlined,
                                color: cs.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_characterPool.length} characters in pool',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _create,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
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
                              'CREATE ROOM',
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
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String label) => Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white38,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
      );

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withOpacity(0.15),
            Colors.transparent,
          ]),
        ),
      );
}

// ── Budget selector ───────────────────────────────────────────────────────────

class _BudgetSelector extends StatelessWidget {
  const _BudgetSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const _options = [500, 750, 1000, 1500, 2000, 3000];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _options.map((opt) {
        final selected = opt == value;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? cs.primary.withOpacity(0.8)
                    : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Text(
              '🪙 $opt',
              style: TextStyle(
                color: selected ? cs.primary : Colors.white54,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Player count selector ─────────────────────────────────────────────────────

class _PlayerCountSelector extends StatelessWidget {
  const _PlayerCountSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(7, (i) {
        final count = i + 2; // 2..8
        final selected = count == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? cs.secondary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? cs.secondary.withOpacity(0.8)
                      : Colors.white.withOpacity(0.15),
                ),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? cs.secondary : Colors.white38,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Universe tile ─────────────────────────────────────────────────────────────

class _UniverseTile extends StatelessWidget {
  const _UniverseTile({
    required this.label,
    required this.selected,
    required this.onToggle,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;

  static const _icons = {
    'Marvel': '🦸',
    'DC': '🦇',
    'Anime': '⚡',
    'Movie': '🎬',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              _icons[label] ?? '🎮',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? cs.primary : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? cs.primary : Colors.white24,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
