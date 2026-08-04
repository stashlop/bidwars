import 'package:equatable/equatable.dart';

import 'battle_round.dart';

class BattleResult extends Equatable {
  final String winnerUid;
  final String winnerName;
  final List<String> playerUids;
  final List<BattleRound> rounds;
  final Map<String, int> scores; // uid → total damage dealt

  const BattleResult({
    required this.winnerUid,
    required this.winnerName,
    required this.playerUids,
    required this.rounds,
    required this.scores,
  });

  factory BattleResult.fromMap(Map<String, dynamic> map) => BattleResult(
        winnerUid: map['winnerUid'] as String? ?? '',
        winnerName: map['winnerName'] as String? ?? '',
        playerUids:
            List<String>.from(map['playerUids'] as List? ?? []),
        rounds: (map['rounds'] as List? ?? [])
            .map((r) => BattleRound.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        scores: Map<String, int>.from(
          (map['scores'] as Map? ?? {}).map(
            (k, v) => MapEntry(k as String, (v as num).toInt()),
          ),
        ),
      );

  Map<String, dynamic> toMap() => {
        'winnerUid': winnerUid,
        'winnerName': winnerName,
        'playerUids': playerUids,
        'rounds': rounds.map((r) => r.toMap()).toList(),
        'scores': scores,
      };

  @override
  List<Object?> get props => [winnerUid, playerUids, rounds, scores];
}
