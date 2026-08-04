import 'package:equatable/equatable.dart';

class BattleRound extends Equatable {
  final int roundNumber;
  final String attackerUid;
  final String attackerName;
  final String defenderUid;
  final String defenderName;
  final String attackerCharacterId;
  final String defenderCharacterId;
  final int damage;
  final String narrativeLine;

  const BattleRound({
    required this.roundNumber,
    required this.attackerUid,
    required this.attackerName,
    required this.defenderUid,
    required this.defenderName,
    required this.attackerCharacterId,
    required this.defenderCharacterId,
    required this.damage,
    required this.narrativeLine,
  });

  factory BattleRound.fromMap(Map<String, dynamic> map) => BattleRound(
        roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 0,
        attackerUid: map['attackerUid'] as String? ?? '',
        attackerName: map['attackerName'] as String? ?? '',
        defenderUid: map['defenderUid'] as String? ?? '',
        defenderName: map['defenderName'] as String? ?? '',
        attackerCharacterId: map['attackerCharacterId'] as String? ?? '',
        defenderCharacterId: map['defenderCharacterId'] as String? ?? '',
        damage: (map['damage'] as num?)?.toInt() ?? 0,
        narrativeLine: map['narrativeLine'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'roundNumber': roundNumber,
        'attackerUid': attackerUid,
        'attackerName': attackerName,
        'defenderUid': defenderUid,
        'defenderName': defenderName,
        'attackerCharacterId': attackerCharacterId,
        'defenderCharacterId': defenderCharacterId,
        'damage': damage,
        'narrativeLine': narrativeLine,
      };

  @override
  List<Object?> get props => [roundNumber, attackerUid, defenderUid, damage];
}
