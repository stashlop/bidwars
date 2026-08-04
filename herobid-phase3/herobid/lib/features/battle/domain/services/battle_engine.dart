import 'dart:math';

import '../models/battle_result.dart';
import '../models/battle_round.dart';

/// Dart-side battle engine — mirrors the Cloud Function logic so the
/// battle can be previewed/tested without a Firebase connection.
///
/// Algorithm:
/// 1. Each team is assigned an ordered list of character stat totals.
/// 2. Characters fight in pairs: slot 0 vs slot 0, slot 1 vs slot 1, etc.
/// 3. The character with the higher total power wins the round, dealing
///    damage = their power - opponent's power (floored at 10).
/// 4. After all pairs, total damage dealt decides the winner.
class BattleEngine {
  BattleEngine._();

  static const _templates = [
    '{attacker} unleashes a devastating blow on {defender}, dealing {damage} damage!',
    '{attacker} outmaneuvers {defender} with blinding speed — {damage} damage landed!',
    '{attacker} channels raw energy, smashing {defender} for {damage} damage!',
    '{attacker} overpowers {defender} through sheer strength — {damage} damage!',
    'With surgical precision, {attacker} strikes {defender} for {damage} damage!',
    '{attacker} dominates this clash, inflicting {damage} damage on {defender}!',
    '{defender} struggles to defend as {attacker} scores {damage} points of damage!',
    '{attacker} seizes the momentum and hits {defender} for {damage} damage!',
  ];

  static final _rng = Random();

  /// Simulate a full battle between two teams.
  ///
  /// [teamA] / [teamB]: maps of characterId → stat total (0–600).
  /// [uidA] / [uidB]: Firebase UIDs of the two players.
  /// [nameA] / [nameB]: display names.
  static BattleResult simulate({
    required String uidA,
    required String nameA,
    required Map<String, int> teamA,
    required String uidB,
    required String nameB,
    required Map<String, int> teamB,
  }) {
    final keysA = teamA.keys.toList();
    final keysB = teamB.keys.toList();
    final roundCount = min(keysA.length, keysB.length);

    final rounds = <BattleRound>[];
    int scoreA = 0;
    int scoreB = 0;

    for (int i = 0; i < roundCount; i++) {
      final charA = keysA[i];
      final charB = keysB[i];
      final powerA = teamA[charA]!;
      final powerB = teamB[charB]!;

      final String attackerUid;
      final String attackerName;
      final String defenderUid;
      final String defenderName;
      final String attackerChar;
      final String defenderChar;
      final int damage;

      if (powerA >= powerB) {
        attackerUid = uidA;
        attackerName = nameA;
        defenderUid = uidB;
        defenderName = nameB;
        attackerChar = charA;
        defenderChar = charB;
        damage = max(10, powerA - powerB);
        scoreA += damage;
      } else {
        attackerUid = uidB;
        attackerName = nameB;
        defenderUid = uidA;
        defenderName = nameA;
        attackerChar = charB;
        defenderChar = charA;
        damage = max(10, powerB - powerA);
        scoreB += damage;
      }

      final template = _templates[_rng.nextInt(_templates.length)];
      final narrative = template
          .replaceAll('{attacker}', _displayName(attackerChar))
          .replaceAll('{defender}', _displayName(defenderChar))
          .replaceAll('{damage}', '$damage');

      rounds.add(BattleRound(
        roundNumber: i + 1,
        attackerUid: attackerUid,
        attackerName: attackerName,
        defenderUid: defenderUid,
        defenderName: defenderName,
        attackerCharacterId: attackerChar,
        defenderCharacterId: defenderChar,
        damage: damage,
        narrativeLine: narrative,
      ));
    }

    final winnerUid = scoreA >= scoreB ? uidA : uidB;
    final winnerName = scoreA >= scoreB ? nameA : nameB;

    return BattleResult(
      winnerUid: winnerUid,
      winnerName: winnerName,
      playerUids: [uidA, uidB],
      rounds: rounds,
      scores: {uidA: scoreA, uidB: scoreB},
    );
  }

  static String _displayName(String id) => id.split('_').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
}
