import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/providers/auth_providers.dart';
import '../../../domain/models/room.dart';
import '../../../domain/models/room_player.dart';
import '../../../domain/providers/room_providers.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));
    final playersAsync = ref.watch(roomPlayersProvider(roomId));

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        if (room == null) {
          return const Scaffold(body: Center(child: Text('Room not found.')));
        }
        // Auto-navigate when room moves to auction
        if (room.status == RoomStatus.auction) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/auction/$roomId');
          });
        }
        return playersAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Scaffold(body: Center(child: Text('Error: $e'))),
          data: (players) =>
              _LobbyView(room: room, players: players, roomId: roomId),
        );
      },
    );
  }
}

class _LobbyView extends ConsumerStatefulWidget {
  const _LobbyView({
    required this.room,
    required this.players,
    required this.roomId,
  });
  final Room room;
  final List<RoomPlayer> players;
  final String roomId;

  @override
  ConsumerState<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends ConsumerState<_LobbyView> {
  bool _myReady = false;

  String? get _myUid =>
      ref.read(authStateChangesProvider).valueOrNull?.uid;

  bool get _isHost => _myUid == widget.room.hostUid;

  bool get _allReady =>
      widget.players.isNotEmpty &&
      widget.players.every((p) => p.isReady || p.isHost);

  Future<void> _toggleReady() async {
    final uid = _myUid;
    if (uid == null) return;
    final next = !_myReady;
    setState(() => _myReady = next);
    await ref.read(roomControllerProvider.notifier).setReady(
          roomId: widget.roomId,
          uid: uid,
          ready: next,
        );
  }

  Future<void> _startAuction() async {
    try {
      await ref.read(roomControllerProvider.notifier).startAuction(widget.roomId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54),
          onPressed: () async {
            final uid = _myUid;
            if (uid != null) {
              await ref.read(roomControllerProvider.notifier).leaveRoom(
                    roomId: widget.roomId,
                    uid: uid,
                  );
            }
            if (!mounted) return;
            context.go('/');
          },
        ),
        title: const Text(
          'LOBBY',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _glow(cs.primary, 320),
          ),
          SafeArea(
            child: Column(
              children: [
                // Room code banner
                _RoomCodeBanner(code: widget.room.code),
                // Player list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: widget.players.length,
                    itemBuilder: (context, i) =>
                        _PlayerTile(player: widget.players[i]),
                  ),
                ),
                // Bottom controls
                _BottomBar(
                  isHost: _isHost,
                  allReady: _allReady,
                  myReady: _myReady,
                  playerCount: widget.players.length,
                  maxPlayers: widget.room.maxPlayers,
                  onToggleReady: _toggleReady,
                  onStartAuction: _startAuction,
                ),
              ],
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
              colors: [color.withOpacity(0.12), Colors.transparent]),
        ),
      );
}

// ── Room code banner ──────────────────────────────────────────────────────────

class _RoomCodeBanner extends StatelessWidget {
  const _RoomCodeBanner({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROOM CODE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white38,
                            letterSpacing: 2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: cs.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room code copied!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player tile ───────────────────────────────────────────────────────────────

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});
  final RoomPlayer player;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player.isReady
              ? cs.primary.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withOpacity(0.2),
            backgroundImage: player.avatarUrl != null
                ? NetworkImage(player.avatarUrl!)
                : null,
            child: player.avatarUrl == null
                ? Text(
                    player.username[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.username,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4)),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '🪙 ${player.coins} coins',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: player.isReady
                  ? cs.primary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: player.isReady
                    ? cs.primary.withOpacity(0.6)
                    : Colors.white12,
              ),
            ),
            child: Text(
              player.isHost ? 'HOST' : (player.isReady ? 'READY' : 'WAITING'),
              style: TextStyle(
                color: player.isReady ? cs.primary : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isHost,
    required this.allReady,
    required this.myReady,
    required this.playerCount,
    required this.maxPlayers,
    required this.onToggleReady,
    required this.onStartAuction,
  });
  final bool isHost;
  final bool allReady;
  final bool myReady;
  final int playerCount;
  final int maxPlayers;
  final VoidCallback onToggleReady;
  final VoidCallback onStartAuction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$playerCount / $maxPlayers players',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
              const SizedBox(height: 12),
              if (isHost)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: allReady ? onStartAuction : null,
                    icon: const Icon(Icons.gavel_rounded),
                    label: Text(
                      allReady ? 'START AUCTION' : 'WAITING FOR PLAYERS…',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onToggleReady,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myReady
                          ? cs.primary.withOpacity(0.2)
                          : cs.primary,
                      foregroundColor: myReady ? cs.primary : Colors.black,
                      side: myReady
                          ? BorderSide(color: cs.primary, width: 1.5)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      myReady ? 'CANCEL READY' : 'READY UP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
