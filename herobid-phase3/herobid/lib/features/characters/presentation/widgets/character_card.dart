import 'package:flutter/material.dart';

import '../../domain/models/character.dart';
import '../../domain/models/character_stats.dart';

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

class CharacterCard extends StatefulWidget {
  const CharacterCard({
    super.key,
    required this.character,
    this.onTap,
    this.compact = false,
  });

  final Character character;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final rarityColor = _rarityColors[c.rarity] ?? Colors.white38;
    final universeColor = _universeColors[c.universe] ?? Colors.white38;

    return ScaleTransition(
      scale: _scale,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          _ctrl.forward();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _ctrl.reverse();
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: rarityColor.withOpacity(_hovered ? 0.7 : 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withOpacity(_hovered ? 0.2 : 0.05),
                  blurRadius: _hovered ? 20 : 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          universeColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: widget.compact ? 44 : 60,
                          height: widget.compact ? 44 : 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: universeColor.withOpacity(0.2),
                            border: Border.all(
                                color: universeColor.withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: universeColor.withOpacity(0.3),
                                  blurRadius: 12),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: universeColor,
                            size: widget.compact ? 26 : 34,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Rarity badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: rarityColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            c.rarity.name.toUpperCase(),
                            style: TextStyle(
                              color: rarityColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info area
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.universe.name.toUpperCase(),
                          style: TextStyle(
                            color: universeColor.withOpacity(0.8),
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        if (!widget.compact) ...[
                          const SizedBox(height: 6),
                          // Stat bars
                          _MiniStatBar(
                            label: 'PWR',
                            value: c.stats.totalPower / 600,
                            color: rarityColor,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '🪙 ${c.basePrice}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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

class _MiniStatBar extends StatelessWidget {
  const _MiniStatBar({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value; // 0–1
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white24, fontSize: 8),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}
