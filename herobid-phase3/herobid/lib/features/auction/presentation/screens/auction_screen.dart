import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/providers/auth_providers.dart';
import '../../../domain/models/auction_item.dart';
import '../../../domain/models/bid.dart';
import '../../../domain/providers/auction_providers.dart';
import '../../../../rooms/domain/models/room.dart';
import '../../../../rooms/domain/providers/room_providers.dart';

// Character display data (since catalog may not be loaded yet, we use ids as display names)
String _characterDisplayName(String id) {
  return id.split('_').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

Color _characterUniverse(String id) {
  const marvelIds = ['iron_man', 'captain_america', 'thor', 'hulk', 'spider_man',
    'black_widow', 'hawkeye', 'doctor_strange', 'black_panther', 'scarlet_witch'];
  const dcIds = ['superman', 'batman', 'wonder_woman', 'the_flash', 'aquaman',
    'green_lantern', 'cyborg', 'shazam', 'green_arrow', 'martian_manhunter'];
  const animeIds = ['goku', 'naruto', 'luffy', 'ichigo', 'saitama',
    'vegeta', 'sasuke', 'zoro', 'eren', 'all_might'];
  if (marvelIds.contains(id)) return const Color(0xFFE63946);
  if (dcIds.contains(id)) return const Color(0xFF2196F3);
  if (animeIds.contains(id)) return const Color(0xFFFF9800);
  return const Color(0xFF9C27B0);
}

class AuctionScreen extends ConsumerStatefulWidget {
  const AuctionScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen>
    with TickerProviderStateMixin {
  final _bidCtrl = TextEditingController();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  int _timeLeft = 30;
  Timer? _localTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    _pulseCtrl.dispose();
    _localTimer?.cancel();
    super.dispose();
  }

  void _syncTimer(int ms) {
    _localTimer?.cancel();
    setState(() => _timeLeft = (ms / 1000).ceil().clamp(0, 999));
    if (_timeLeft > 0) {
      _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _timeLeft = (_timeLeft - 1).clamp(0, 999);
        });
      });
    }
  }

  Future<void> _placeBid(int amount) async {
    try {
      await ref.read(bidControllerProvider.notifier).placeBid(
            roomId: widget.roomId,
            amount: amount,
          );
      _bidCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auctionAsync = ref.watch(auctionItemProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final bidsAsync = ref.watch(recentBidsProvider(widget.roomId));
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    final cs = Theme.of(context).colorScheme;

    // Auto-navigate when auction ends
    roomAsync.whenData((room) {
      if (room != null && room.status == RoomStatus.teamBuilder) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/team/${widget.roomId}');
        });
      }
    });

    return auctionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('Auction starting…')),
          );
        }
        // Sync local timer when timeLeftMs changes
        if (item.timeLeftMs > 0) _syncTimer(item.timeLeftMs);

        final color = _characterUniverse(item.characterId);
        final myCoins = 999; // Placeholder — would come from room player doc

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(item, cs),
          body: Stack(
            children: [
              // Ambient glow matching universe color
              Positioned(
                top: -100,
                left: MediaQuery.of(context).size.width / 2 - 200,
                child: _glow(color, 400),
              ),
              Positioned(bottom: 120, right: -60, child: _glow(cs.secondary, 200)),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Character hero card
                    _CharacterHeroCard(
                      characterId: item.characterId,
                      color: color,
                      pulse: _pulse,
                    ),
                    const SizedBox(height: 16),
                    // Bid info row
                    _BidInfoRow(
                      item: item,
                      timeLeft: _timeLeft,
                      cs: cs,
                    ),
                    const SizedBox(height: 12),
                    // Bid feed
                    Expanded(
                      child: bidsAsync.when(
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                        data: (bids) => _BidFeed(bids: bids, myUid: myUid),
                      ),
                    ),
                    // Bid input bar
                    _BidInputBar(
                      item: item,
                      ctrl: _bidCtrl,
                      onBid: _placeBid,
                      myCoins: myCoins,
                      cs: cs,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(AuctionItem item, ColorScheme cs) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'AUCTION  ${item.itemIndex + 1} / ${item.totalItems}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 14,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withOpacity(0.18), Colors.transparent]),
        ),
      );
}

// ── Character hero card ───────────────────────────────────────────────────────

class _CharacterHeroCard extends StatelessWidget {
  const _CharacterHeroCard({
    required this.characterId,
    required this.color,
    required this.pulse,
  });
  final String characterId;
  final Color color;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: ScaleTransition(
                    scale: pulse,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.2),
                            border: Border.all(color: color.withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 0),
                            ],
                          ),
                          child: Icon(Icons.person, color: color, size: 44),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _characterDisplayName(characterId),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                  color: color.withOpacity(0.8),
                                  blurRadius: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bid info row ──────────────────────────────────────────────────────────────

class _BidInfoRow extends StatelessWidget {
  const _BidInfoRow({
    required this.item,
    required this.timeLeft,
    required this.cs,
  });
  final AuctionItem item;
  final int timeLeft;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              label: 'CURRENT BID',
              value: '🪙 ${item.currentBid}',
              sub: item.currentBidderName ?? '—',
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoTile(
              label: 'TIME LEFT',
              value: '$timeLeft s',
              sub: timeLeft <= 5 ? '⚡ HURRY!' : 'seconds',
              color: timeLeft <= 10 ? cs.secondary : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white38, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          Text(sub,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Bid feed ──────────────────────────────────────────────────────────────────

class _BidFeed extends StatelessWidget {
  const _BidFeed({required this.bids, this.myUid});
  final List<Bid> bids;
  final String? myUid;

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return Center(
        child: Text('No bids yet. Be the first!',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white24)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: bids.length,
      itemBuilder: (context, i) {
        final bid = bids[i];
        final isMe = bid.uid == myUid;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? cs.primary.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMe
                        ? cs.primary.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bid.username,
                      style: TextStyle(
                        color: isMe ? cs.primary : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🪙 ${bid.amount}',
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Bid input bar ─────────────────────────────────────────────────────────────

class _BidInputBar extends StatelessWidget {
  const _BidInputBar({
    required this.item,
    required this.ctrl,
    required this.onBid,
    required this.myCoins,
    required this.cs,
  });
  final AuctionItem item;
  final TextEditingController ctrl;
  final ValueChanged<int> onBid;
  final int myCoins;
  final ColorScheme cs;

  static const _quickBids = [50, 100, 200, 500];

  @override
  Widget build(BuildContext context) {
    final minBid = item.currentBid + 10;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick-bid chips
              Row(
                children: _quickBids.map((q) {
                  final amount = minBid + q;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: item.isActive ? () => onBid(amount) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            '+$q',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Custom bid (min $minBid)',
                        hintStyle:
                            const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: cs.primary.withOpacity(0.6), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: item.isActive
                        ? () {
                            final val = int.tryParse(ctrl.text.trim());
                            if (val != null && val >= minBid) onBid(val);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'BID',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
