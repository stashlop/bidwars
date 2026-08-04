import 'package:equatable/equatable.dart';

class CharacterStats extends Equatable {
  final int strength;
  final int speed;
  final int intelligence;
  final int durability;
  final int energy;
  final int fightingSkill;

  const CharacterStats({
    required this.strength,
    required this.speed,
    required this.intelligence,
    required this.durability,
    required this.energy,
    required this.fightingSkill,
  });

  /// Total power score (0–600).
  int get totalPower =>
      strength + speed + intelligence + durability + energy + fightingSkill;

  factory CharacterStats.fromMap(Map<String, dynamic> map) => CharacterStats(
        strength: (map['strength'] as num?)?.toInt() ?? 50,
        speed: (map['speed'] as num?)?.toInt() ?? 50,
        intelligence: (map['intelligence'] as num?)?.toInt() ?? 50,
        durability: (map['durability'] as num?)?.toInt() ?? 50,
        energy: (map['energy'] as num?)?.toInt() ?? 50,
        fightingSkill: (map['fightingSkill'] as num?)?.toInt() ?? 50,
      );

  Map<String, dynamic> toMap() => {
        'strength': strength,
        'speed': speed,
        'intelligence': intelligence,
        'durability': durability,
        'energy': energy,
        'fightingSkill': fightingSkill,
      };

  @override
  List<Object?> get props =>
      [strength, speed, intelligence, durability, energy, fightingSkill];
}
