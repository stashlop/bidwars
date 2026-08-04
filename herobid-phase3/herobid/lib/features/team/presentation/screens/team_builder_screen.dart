import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/team_slot.dart';
import '../../../domain/providers/team_providers.dart';
import '../../../../rooms/domain/models/room.dart';
import '../../../../rooms/domain/providers/room_providers.dart';

String _displayName(String id) => id.split('_').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');

class TeamBuilderScreen extends ConsumerStatefulWidget {
  const TeamBuilderScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends ConsumerState<TeamBuilderScreen> {
  // Null means no character is being dragged; non-null = characterId being dragged
  String? _dragging;

  Future<void> _onDropSlot(int position, String characterId) async {
    await ref.read(teamControllerProvider.notifier).assignSlot(
          roomId: widget.roomId,
          position: position,
          characterId: characterId,
          characterName: _displayName(characterId),
        );
  }

  Future<void> _lockTeam(List<TeamSlot> slots) async {
    if (slots.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assign at least 3 characters to lock your team.')),
      );
      return;
    }
    try {
      await ref.read(teamControllerProvider.notifier).lockTeam(widget.roomId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wonAsync = ref.watch(myWonCharactersProvider(widget.roomId));
    final teamAsync = ref.watch(myTeamProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final cs = Theme.of(context).colorScheme;

    // Auto-navigate when battle starts
    roomAsync.whenData((room) {
      if (room != null && room.status == RoomStatus.battle) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/battle/${widget.roomId}');
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'BUILD YOUR TEAM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
              top: -100, left: -80, child: _glow(cs.primary, 320)),
          Positioned(
              bottom: -60, right: -60, child: _glow(cs.secondary, 250)),
          SafeArea(
            child: teamAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (slots) => wonAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (wonIds) => _buildBody(context, slots, wonIds, cs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<TeamSlot> slots,
    List<String> wonIds,
    ColorScheme cs,
  ) {
    // Characters already in a slot
    final assignedIds =
        slots.map((s) => s.characterId).whereType<String>().toSet();
    final available =
        wonIds.where((id) => !assignedIds.contains(id)).toList();

    // Build a map from position→slot for fast lookup
    final slotMap = {for (final s in slots) s.position: s};

    return Column(
      children: [
        const SizedBox(height: 8),
        // Instruction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Drag characters from your bench into formation slots.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white38, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Formation: 5 slots in a 2-3 grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _FormationGrid(
            slotMap: slotMap,
            onDrop: _onDropSlot,
            onClear: (pos) => ref
                .read(teamControllerProvider.notifier)
                .clearSlot(roomId: widget.roomId, position: pos),
            dragging: _dragging,
          ),
        ),
        const SizedBox(height: 24),
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('BENCH',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white24, letterSpacing: 2)),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
          ]),
        ),
        const SizedBox(height: 12),
        // Bench: won characters not yet assigned
        Expanded(
          child: available.isEmpty
              ? Center(
                  child: Text(
                    wonIds.isEmpty
                        ? 'You didn\'t win any characters.'
                        : 'All characters assigned!',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white24),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: available.length,
                  itemBuilder: (context, i) {
                    final id = available[i];
                    return Draggable<String>(
                      data: id,
                      onDragStarted: () => setState(() => _dragging = id),
                      onDragEnd: (_) => setState(() => _dragging = null),
                      feedback: Material(
                        color: Colors.transparent,
                        child: _BenchCard(
                          characterId: id,
                          cs: cs,
                          opacity: 0.9,
                        ),
                      ),
                      childWhenDragging:
                          _BenchCard(characterId: id, cs: cs, opacity: 0.3),
                      child: _BenchCard(characterId: id, cs: cs),
                    );
                  },
                ),
        ),
        // Lock team button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _lockTeam(slots),
              icon: const Icon(Icons.lock_rounded),
              label: const Text(
                'LOCK TEAM',
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
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

// ── Formation grid ────────────────────────────────────────────────────────────

class _FormationGrid extends StatelessWidget {
  const _FormationGrid({
    required this.slotMap,
    required this.onDrop,
    required this.onClear,
    required this.dragging,
  });
  final Map<int, TeamSlot> slotMap;
  final Future<void> Function(int position, String characterId) onDrop;
  final Future<void> Function(int position) onClear;
  final String? dragging;

  @override
  Widget build(BuildContext context) {
    // 2-1-2 formation
    return Column(
      children: [
        Row(
          children: [0, 1]
              .map((pos) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _SlotTarget(
                        position: pos,
                        slot: slotMap[pos],
                        isDraggingActive: dragging != null,
                        onDrop: onDrop,
                        onClear: onClear,
                      ),
                    ),
                  ))
              .toList(),
        ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _SlotTarget(
                  position: 2,
                  slot: slotMap[2],
                  isDraggingActive: dragging != null,
                  onDrop: onDrop,
                  onClear: onClear,
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        Row(
          children: [3, 4]
              .map((pos) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _SlotTarget(
                        position: pos,
                        slot: slotMap[pos],
                        isDraggingActive: dragging != null,
                        onDrop: onDrop,
                        onClear: onClear,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _SlotTarget extends StatelessWidget {
  const _SlotTarget({
    required this.position,
    required this.slot,
    required this.isDraggingActive,
    required this.onDrop,
    required this.onClear,
  });
  final int position;
  final TeamSlot? slot;
  final bool isDraggingActive;
  final Future<void> Function(int, String) onDrop;
  final Future<void> Function(int) onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = slot != null && slot!.characterId != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDrop(position, details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: filled ? () => onClear(position) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 90,
            decoration: BoxDecoration(
              color: filled
                  ? cs.primary.withOpacity(0.15)
                  : isHovered
                      ? cs.primary.withOpacity(0.1)
                      : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: filled
                    ? cs.primary.withOpacity(0.6)
                    : isHovered
                        ? cs.primary.withOpacity(0.5)
                        : isDraggingActive
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.08),
                width: isHovered ? 2 : 1.5,
              ),
            ),
            child: filled
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: cs.primary, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        slot!.characterName ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: isHovered ? cs.primary : Colors.white24,
                        size: 28,
                      ),
                      Text(
                        'Slot ${position + 1}',
                        style: TextStyle(
                          color: isHovered ? cs.primary : Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ── Bench card ────────────────────────────────────────────────────────────────

class _BenchCard extends StatelessWidget {
  const _BenchCard({
    required this.characterId,
    required this.cs,
    this.opacity = 1.0,
  });
  final String characterId;
  final ColorScheme cs;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: cs.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.secondary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withOpacity(0.2),
              ),
              child: Icon(Icons.person, color: cs.secondary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              _displayName(characterId),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
