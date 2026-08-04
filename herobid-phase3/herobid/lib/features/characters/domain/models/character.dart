import 'package:equatable/equatable.dart';

import 'character_stats.dart';

enum CharacterUniverse { marvel, dc, anime, movie }

CharacterUniverse universeFromString(String s) {
  switch (s.toLowerCase()) {
    case 'dc':
      return CharacterUniverse.dc;
    case 'anime':
      return CharacterUniverse.anime;
    case 'movie':
      return CharacterUniverse.movie;
    default:
      return CharacterUniverse.marvel;
  }
}

enum CharacterRarity { common, rare, epic, legendary }

CharacterRarity rarityFromString(String s) {
  switch (s.toLowerCase()) {
    case 'rare':
      return CharacterRarity.rare;
    case 'epic':
      return CharacterRarity.epic;
    case 'legendary':
      return CharacterRarity.legendary;
    default:
      return CharacterRarity.common;
  }
}

class Character extends Equatable {
  final String id;
  final String name;
  final CharacterUniverse universe;
  final CharacterRarity rarity;
  final String? imageUrl;
  final String description;
  final CharacterStats stats;
  final int basePrice;

  const Character({
    required this.id,
    required this.name,
    required this.universe,
    required this.rarity,
    this.imageUrl,
    required this.description,
    required this.stats,
    required this.basePrice,
  });

  factory Character.fromMap(String id, Map<String, dynamic> map) => Character(
        id: id,
        name: map['name'] as String? ?? id,
        universe: universeFromString(map['universe'] as String? ?? 'marvel'),
        rarity: rarityFromString(map['rarity'] as String? ?? 'common'),
        imageUrl: map['imageUrl'] as String?,
        description: map['description'] as String? ?? '',
        stats: CharacterStats.fromMap(
            Map<String, dynamic>.from(map['stats'] as Map? ?? {})),
        basePrice: (map['basePrice'] as num?)?.toInt() ?? 100,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'universe': universe.name,
        'rarity': rarity.name,
        'imageUrl': imageUrl,
        'description': description,
        'stats': stats.toMap(),
        'basePrice': basePrice,
      };

  @override
  List<Object?> get props =>
      [id, name, universe, rarity, imageUrl, description, stats, basePrice];
}
