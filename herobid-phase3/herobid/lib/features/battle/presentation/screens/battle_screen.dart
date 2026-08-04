import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/providers/auth_providers.dart';
import '../../../domain/models/battle_result.dart';
import '../../../domain/models/battle_round.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final battleResultProvider =
    StreamProvider.family<BattleResult?, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('battle')
      .doc('result')
      .snapshots()
      .map((s) => s.exists ? BattleResult.fromMap(s.data()!) : null);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  int _currentRound = 0;
  bool _showWinner = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim =
        Tween<double>(begin: 0.3, end: 1.0).animate(_glowCtrl);
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _nextRound(int total) {
    if (_currentRound < total - 1) {
      setState(() => _currentRound++);
      _slideCtrl.forward(from: 0);
    } else {
      setState(() => _showWinner = true);
      _slideCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(battleResultProvider(widget.roomId));
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    final cs = Theme.of(context).colorScheme;

    return resultAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculating battle…', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (result) {
        if (result == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for battle to start…',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          );
        }

        final isWinner = result.winnerUid == myUid;
        final rounds = result.rounds;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _showWinner ? '⚔️ BATTLE RESULT' : 'ROUND ${_currentRound + 1} / ${rounds.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Background glow
              Positioned(
                top: -100,
                left: MediaQuery.of(context).size.width / 2 - 200,
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => _glow(
                    _showWinner
                        ? (isWinner ? cs.primary : cs.secondary)
                        : cs.secondary,
                    400,
                    _glowAnim.value,
                  ),
                ),
              ),
              SafeArea(
                child: _showWinner
                    ? _WinnerView(
                        result: result,
                        myUid: myUid,
                        isWinner: isWinner,
                        slideAnim: _slideAnim,
                        onDone: () => context.go('/'),
                        cs: cs,
                      )
                    : _RoundView(
                        round: rounds[_currentRound],
                        slideAnim: _slideAnim,
                        onNext: () => _nextRound(rounds.length),
                        isLast: _currentRound == rounds.length - 1,
                        cs: cs,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glow(Color color, double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity * 0.2), Colors.transparent],
          ),
        ),
      );
}

// ── Round view ────────────────────────────────────────────────────────────────

class _RoundView extends StatelessWidget {
  const _RoundView({
    required this.round,
    required this.slideAnim,
    required this.onNext,
    required this.isLast,
    required this.cs,
  });
  final BattleRound round;
  final Animation<Offset> slideAnim;
  final VoidCallback onNext;
  final bool isLast;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // VS header
          Row(
            children: [
              Expanded(
                child: _PlayerBadge(
                  name: round.attackerName,
                  characterId: round.attackerCharacterId,
                  color: cs.primary,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.secondary.withOpacity(0.5)),
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: cs.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: _PlayerBadge(
                  name: round.defenderName,
                  characterId: round.defenderCharacterId,
                  color: Colors.white38,
                  align: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Narrative card
          Expanded(
            child: SlideTransition(
              position: slideAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, color: cs.secondary, size: 48),
                        const SizedBox(height: 20),
                        Text(
                          round.narrativeLine,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    const Color(0xFFFFD700).withOpacity(0.4)),
                          ),
                          child: Text(
                            '⚡ ${round.damage} damage',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isLast ? 'SEE RESULTS ⚔️' : 'NEXT ROUND →',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({
    required this.name,
    required this.characterId,
    required this.color,
    this.align = TextAlign.left,
  });
  final String name;
  final String characterId;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: align,
        ),
        Text(
          characterId.split('_').map((w) {
            if (w.isEmpty) return w;
            return w[0].toUpperCase() + w.substring(1);
          }).join(' '),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          textAlign: align,
        ),
      ],
    );
  }
}

// ── Winner view ───────────────────────────────────────────────────────────────

class _WinnerView extends StatelessWidget {
  const _WinnerView({
    required this.result,
    required this.myUid,
    required this.isWinner,
    required this.slideAnim,
    required this.onDone,
    required this.cs,
  });
  final BattleResult result;
  final String? myUid;
  final bool isWinner;
  final Animation<Offset> slideAnim;
  final VoidCallback onDone;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final color = isWinner ? cs.primary : cs.secondary;
    final myScore = myUid != null ? (result.scores[myUid] ?? 0) : 0;
    final oppScore = result.scores.entries
        .where((e) => e.key != myUid)
        .fold(0, (acc, e) => acc + e.value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SlideTransition(
        position: slideAnim,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Trophy / skull
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4), blurRadius: 30),
                ],
              ),
              child: Icon(
                isWinner ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 60,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isWinner ? 'VICTORY!' : 'DEFEATED',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 4,
                shadows: [Shadow(color: color.withOpacity(0.8), blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.winnerName} wins this battle!',
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 32),
            // Score board
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'DAMAGE SCORE',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                                color: Colors.white38, letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ScoreBox(
                            label: 'YOUR SCORE',
                            score: myScore,
                            color: isWinner ? cs.primary : Colors.white38,
                          ),
                          Container(
                            height: 50,
                            width: 1,
                            color: Colors.white12,
                          ),
                          _ScoreBox(
                            label: 'OPPONENT',
                            score: oppScore,
                            color: !isWinner ? cs.primary : Colors.white38,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Round summary
            ...result.rounds.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      'Round ${r.roundNumber}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.narrativeLine,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚡${r.damage}',
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
