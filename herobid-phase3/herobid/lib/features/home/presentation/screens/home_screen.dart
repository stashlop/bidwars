import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/models/app_user.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../widgets/action_card.dart';
import '../widgets/stat_chip.dart';

// ─── Rank helpers ────────────────────────────────────────────────────────────

Color _rankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'silver':
      return const Color(0xFFC0C0C0);
    case 'gold':
      return const Color(0xFFFFD700);
    case 'platinum':
      return const Color(0xFFE5E4E2);
    case 'diamond':
      return const Color(0xFF00BFFF);
    case 'legend':
      return const Color(0xFFFF2E9A);
    default:
      return Colors.white38; // Unranked
  }
}

IconData _rankIcon(String rank) {
  switch (rank.toLowerCase()) {
    case 'bronze':
      return Icons.shield_outlined;
    case 'silver':
      return Icons.shield;
    case 'gold':
      return Icons.military_tech;
    case 'platinum':
      return Icons.stars;
    case 'diamond':
      return Icons.diamond;
    case 'legend':
      return Icons.auto_awesome;
    default:
      return Icons.person_outline;
  }
}

String _winRate(AppUser user) {
  final played = user.wins + user.losses;
  if (played == 0) return '—';
  return '${(user.wins / played * 100).toStringAsFixed(0)}%';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) => user == null
          ? _LoadingProfileView(ref: ref)
          : _HomeView(user: user, ref: ref),
    );
  }
}

// ─── Loading profile view ────────────────────────────────────────────────────

class _LoadingProfileView extends StatelessWidget {
  const _LoadingProfileView({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Setting up your profile…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This only happens on first sign-in.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Sign out and try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main home view ──────────────────────────────────────────────────────────

class _HomeView extends StatelessWidget {
  const _HomeView({required this.user, required this.ref});
  final AppUser user;
  final WidgetRef ref;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature launches in Phase 5!'),
        backgroundColor: const Color(0xFF15151F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2EE6FF), width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(user.currentRank);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, rankColor),
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -100,
            left: size.width * 0.5 - 200,
            child: _ambientGlow(const Color(0xFF2EE6FF), 400),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _ambientGlow(const Color(0xFFFF2E9A), 300),
          ),
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _profileCard(context, rankColor),
                  const SizedBox(height: 20),
                  _statsRow(context),
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'PLAY'),
                  const SizedBox(height: 12),
                  _actionCards(context),
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'MY COLLECTION'),
                  const SizedBox(height: 12),
                  _collectionPlaceholder(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, Color rankColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: const Color(0xFF2EE6FF), size: 22),
          const SizedBox(width: 6),
          Text(
            'HeroBid',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          tooltip: 'Sign out',
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────

  Widget _profileCard(BuildContext context, Color rankColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2EE6FF),
                      const Color(0xFFFF2E9A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              // Name + rank
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white38),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    // Rank badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rankColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _rankIcon(user.currentRank),
                            color: rankColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.currentRank,
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // XP column
              Column(
                children: [
                  Text(
                    '${user.xp}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF2EE6FF),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'XP',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _statsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatChip(
            icon: Icons.monetization_on_rounded,
            value: '${user.coins}',
            label: 'COINS',
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.emoji_events_rounded,
            value: '${user.wins}',
            label: 'WINS',
            color: const Color(0xFF2EE6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.close_rounded,
            value: '${user.losses}',
            label: 'LOSSES',
            color: const Color(0xFFFF2E9A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatChip(
            icon: Icons.percent_rounded,
            value: _winRate(user),
            label: 'WIN RATE',
            color: const Color(0xFF9B59B6),
          ),
        ),
      ],
    );
  }

  // ── Action cards ─────────────────────────────────────────────────────────

  Widget _actionCards(BuildContext context) {
    return Column(
      children: [
        ActionCard(
          title: 'Create Room',
          subtitle:
              'Host a bidding room and invite up to 8 players to compete for characters.',
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF2EE6FF),
          comingSoon: true,
          onTap: () => _showComingSoon(context, 'Create Room'),
        ),
        const SizedBox(height: 12),
        ActionCard(
          title: 'Join Room',
          subtitle:
              'Enter a room code to join a live auction already in progress.',
          icon: Icons.login_rounded,
          color: const Color(0xFFFF2E9A),
          comingSoon: true,
          onTap: () => _showComingSoon(context, 'Join Room'),
        ),
      ],
    );
  }

  // ── Collection placeholder ────────────────────────────────────────────────

  Widget _collectionPlaceholder(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 14),
              Text(
                user.charactersOwned == 0
                    ? 'No characters yet'
                    : '${user.charactersOwned} characters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Win auctions to build your roster.\nRooms open in Phase 5.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white24, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white38,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _ambientGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
