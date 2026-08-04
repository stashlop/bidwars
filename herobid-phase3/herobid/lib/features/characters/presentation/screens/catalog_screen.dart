import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/character.dart';
import '../../domain/models/character_stats.dart';
import '../../domain/providers/character_providers.dart';
import '../widgets/character_card.dart';

const _universeIcons = {
  CharacterUniverse.marvel: '🦸',
  CharacterUniverse.dc: '🦇',
  CharacterUniverse.anime: '⚡',
  CharacterUniverse.movie: '🎬',
};

const _rarityColors = {
  CharacterRarity.common: Color(0xFF9E9E9E),
  CharacterRarity.rare: Color(0xFF2196F3),
  CharacterRarity.epic: Color(0xFF9C27B0),
  CharacterRarity.legendary: Color(0xFFFFD700),
};

const _universeColors = {
  CharacterUniverse.marvel: Color(0xFFE63946),
  CharacterUniverse.dc: Color(0xFF2196F3),
  CharacterUniverse.anime: Color(0xFFFF9800),
  CharacterUniverse.movie: Color(0xFF9C27B0),
};

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  CharacterUniverse? _filterUniverse;
  CharacterRarity? _filterRarity;
  Character? _selected;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(characterSearchQueryProvider);
    var characters = ref.watch(characterSearchProvider);

    if (_filterUniverse != null) {
      characters =
          characters.where((c) => c.universe == _filterUniverse).toList();
    }
    if (_filterRarity != null) {
      characters =
          characters.where((c) => c.rarity == _filterRarity).toList();
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CHARACTER CATALOG',
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
              top: -80,
              left: -60,
              child: _glow(cs.primary, 300)),
          Positioned(
              bottom: -60,
              right: -60,
              child: _glow(cs.secondary, 250)),
          SafeArea(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or universe…',
                          hintStyle: const TextStyle(
                              color: Colors.white24, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.07),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: cs.primary.withOpacity(0.6),
                                width: 1.5),
                          ),
                        ),
                        onChanged: (v) => ref
                            .read(characterSearchQueryProvider.notifier)
                            .state = v,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Universe filters
                      ...CharacterUniverse.values.map((u) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label:
                                  '${_universeIcons[u]} ${u.name.toUpperCase()}',
                              selected: _filterUniverse == u,
                              color: _universeColors[u] ?? cs.primary,
                              onTap: () => setState(() {
                                _filterUniverse =
                                    _filterUniverse == u ? null : u;
                              }),
                            ),
                          )),
                      // Rarity filters
                      ...CharacterRarity.values.map((r) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: r.name.toUpperCase(),
                              selected: _filterRarity == r,
                              color: _rarityColors[r] ?? Colors.white38,
                              onTap: () => setState(() {
                                _filterRarity =
                                    _filterRarity == r ? null : r;
                              }),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${characters.length} characters',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.white24, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: characters.length,
                    itemBuilder: (context, i) => CharacterCard(
                      character: characters[i],
                      onTap: () => _showDetail(context, characters[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Character c) {
    final rarityColor = _rarityColors[c.rarity] ?? Colors.white38;
    final universeColor = _universeColors[c.universe] ?? Colors.white38;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CharacterDetailSheet(
        character: c,
        rarityColor: rarityColor,
        universeColor: universeColor,
        cs: cs,
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color.withOpacity(0.7) : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white38,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Character detail sheet ────────────────────────────────────────────────────

class _CharacterDetailSheet extends StatelessWidget {
  const _CharacterDetailSheet({
    required this.character,
    required this.rarityColor,
    required this.universeColor,
    required this.cs,
  });
  final Character character;
  final Color rarityColor;
  final Color universeColor;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final c = character;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B14).withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: rarityColor.withOpacity(0.3)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Character icon
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: universeColor.withOpacity(0.15),
                      border: Border.all(
                          color: universeColor.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: universeColor.withOpacity(0.4),
                            blurRadius: 24),
                      ],
                    ),
                    child: Icon(Icons.person, color: universeColor, size: 50),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: universeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: universeColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          c.universe.name.toUpperCase(),
                          style: TextStyle(
                              color: universeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: rarityColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          c.rarity.name.toUpperCase(),
                          style: TextStyle(
                              color: rarityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  c.description,
                  style: const TextStyle(
                      color: Colors.white54, height: 1.6, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Stats
                Text(
                  'STATS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white38, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                ..._buildStatRows(c.stats, rarityColor),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Price',
                          style: TextStyle(color: Colors.white54)),
                      Text(
                        '🪙 ${c.basePrice}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    );
  }

  List<Widget> _buildStatRows(CharacterStats s, Color color) {
    final stats = [
      ('Strength', s.strength),
      ('Speed', s.speed),
      ('Intelligence', s.intelligence),
      ('Durability', s.durability),
      ('Energy', s.energy),
      ('Fighting Skill', s.fightingSkill),
    ];
    return stats.map((st) {
      final (label, value) = st;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
