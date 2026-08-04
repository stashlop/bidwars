import 'package:flutter_test/flutter_test.dart';
import 'package:herobid/features/auth/domain/models/app_user.dart';
import 'package:herobid/features/characters/domain/models/character.dart';

void main() {
  group('AppUser', () {
    test('round-trips through toMap/fromMap', () {
      const user = AppUser(uid: 'u1', username: 'Stash', coins: 850, wins: 3, losses: 1);
      final rebuilt = AppUser.fromMap('u1', user.toMap());
      expect(rebuilt, user);
    });

    test('computes win rate from wins and losses', () {
      const user = AppUser(uid: 'u1', username: 'Stash', wins: 3, losses: 1);
      expect(user.winRate, 0.75);
    });

    test('winRate is zero with no matches played', () {
      const user = AppUser(uid: 'u1', username: 'Stash');
      expect(user.winRate, 0);
    });
  });

  group('CharacterStats', () {
    test('overall is the rounded mean of the six stats', () {
      const stats = CharacterStats(
        power: 90,
        speed: 80,
        durability: 70,
        intelligence: 60,
        magic: 50,
        combat: 100,
      );
      expect(stats.overall, 75);
    });
  });
}
