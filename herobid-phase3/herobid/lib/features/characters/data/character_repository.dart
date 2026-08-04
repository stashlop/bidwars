import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/character.dart';
import '../domain/models/character_stats.dart';

/// Hardcoded catalog — written here so the app works without a seeded
/// Firestore. Characters are also persisted to Firestore via the
/// `seedCharacters` Cloud Function (admin-only) so they can be
/// extended without a client deploy.
const _catalog = [
  // ── Marvel ────────────────────────────────────────────────────────────
  ('iron_man', 'Iron Man', 'marvel', 'legendary', 'Genius billionaire in a powered armour suit.', 100, 90, 100, 80, 85, 80, 200),
  ('captain_america', 'Captain America', 'marvel', 'epic', 'Super-soldier with vibranium shield.', 90, 60, 75, 95, 10, 95, 150),
  ('thor', 'Thor', 'marvel', 'legendary', 'Asgardian god of thunder.', 100, 80, 70, 100, 100, 85, 200),
  ('hulk', 'Hulk', 'marvel', 'legendary', 'The angrier he gets, the stronger he becomes.', 100, 50, 40, 100, 50, 70, 180),
  ('spider_man', 'Spider-Man', 'marvel', 'epic', 'Friendly neighbourhood web-slinger.', 80, 95, 85, 65, 40, 90, 140),
  ('black_widow', 'Black Widow', 'marvel', 'rare', 'Elite spy and martial artist.', 60, 80, 85, 50, 10, 100, 100),
  ('hawkeye', 'Hawkeye', 'marvel', 'rare', 'World\'s greatest marksman.', 50, 70, 80, 50, 10, 90, 80),
  ('doctor_strange', 'Doctor Strange', 'marvel', 'epic', 'Sorcerer Supreme.', 60, 70, 100, 60, 100, 60, 160),
  ('black_panther', 'Black Panther', 'marvel', 'epic', 'King of Wakanda.', 90, 90, 90, 80, 10, 95, 160),
  ('scarlet_witch', 'Scarlet Witch', 'marvel', 'legendary', 'Reality-warping chaos magic.', 70, 70, 100, 70, 100, 70, 180),
  // ── DC ────────────────────────────────────────────────────────────────
  ('superman', 'Superman', 'dc', 'legendary', 'Last son of Krypton.', 100, 100, 80, 100, 100, 85, 200),
  ('batman', 'Batman', 'dc', 'epic', 'Dark Knight of Gotham.', 70, 75, 100, 70, 25, 100, 150),
  ('wonder_woman', 'Wonder Woman', 'dc', 'epic', 'Amazonian warrior princess.', 95, 85, 85, 95, 80, 95, 160),
  ('the_flash', 'The Flash', 'dc', 'epic', 'Fastest man alive.', 40, 100, 80, 60, 60, 75, 140),
  ('aquaman', 'Aquaman', 'dc', 'rare', 'King of Atlantis.', 95, 70, 70, 90, 60, 85, 110),
  ('green_lantern', 'Green Lantern', 'dc', 'rare', 'Intergalactic cop with a power ring.', 65, 70, 75, 65, 90, 70, 100),
  ('cyborg', 'Cyborg', 'dc', 'rare', 'Half-man, half-machine.', 75, 65, 80, 80, 85, 65, 90),
  ('shazam', 'Shazam', 'dc', 'epic', 'Magic-powered superman equivalent.', 95, 90, 60, 95, 90, 70, 140),
  ('green_arrow', 'Green Arrow', 'dc', 'common', 'Master archer and vigilante.', 50, 70, 75, 55, 10, 95, 70),
  ('martian_manhunter', 'Martian Manhunter', 'dc', 'legendary', 'Telepathic shapeshifter.', 90, 90, 100, 90, 100, 85, 190),
  // ── Anime ─────────────────────────────────────────────────────────────
  ('goku', 'Goku', 'anime', 'legendary', 'Saiyan who surpasses his limits.', 100, 100, 60, 100, 100, 100, 200),
  ('naruto', 'Naruto', 'anime', 'legendary', 'Ninja with infinite chakra.', 85, 90, 70, 85, 100, 90, 190),
  ('luffy', 'Luffy', 'anime', 'epic', 'Rubber-bodied pirate king.', 90, 80, 60, 85, 10, 90, 150),
  ('ichigo', 'Ichigo', 'anime', 'epic', 'Substitute Soul Reaper.', 90, 85, 70, 85, 80, 90, 150),
  ('saitama', 'Saitama', 'anime', 'legendary', 'One punch is all it takes.', 100, 80, 60, 100, 100, 100, 200),
  ('vegeta', 'Vegeta', 'anime', 'legendary', 'Prince of all Saiyans.', 100, 95, 70, 100, 100, 95, 195),
  ('sasuke', 'Sasuke', 'anime', 'epic', 'Sharingan prodigy.', 80, 90, 90, 75, 90, 90, 150),
  ('zoro', 'Zoro', 'anime', 'epic', 'Three-sword style master.', 90, 70, 60, 85, 10, 100, 140),
  ('eren', 'Eren Yeager', 'anime', 'rare', 'Titan-shifting soldier.', 85, 60, 70, 90, 75, 75, 110),
  ('all_might', 'All Might', 'anime', 'legendary', 'Symbol of Peace.', 100, 90, 75, 100, 60, 100, 200),
  // ── Movie ─────────────────────────────────────────────────────────────
  ('john_wick', 'John Wick', 'movie', 'epic', 'The Boogeyman.', 70, 85, 80, 65, 10, 100, 140),
  ('neo', 'Neo', 'movie', 'epic', 'The One.', 80, 90, 90, 80, 60, 90, 150),
  ('terminator', 'Terminator', 'movie', 'epic', 'T-800 killing machine.', 100, 50, 80, 100, 70, 70, 130),
  ('gandalf', 'Gandalf', 'movie', 'legendary', 'You shall not pass.', 60, 50, 100, 70, 100, 60, 170),
  ('dumbledore', 'Dumbledore', 'movie', 'legendary', 'Greatest wizard of his age.', 55, 50, 100, 65, 100, 60, 160),
  ('predator', 'Predator', 'movie', 'rare', 'Alien trophy hunter.', 85, 75, 70, 85, 50, 90, 110),
  ('ripley', 'Ripley', 'movie', 'rare', 'Survivor of the Nostromo.', 50, 65, 85, 60, 20, 80, 90),
  ('morpheus', 'Morpheus', 'movie', 'rare', 'Captain of the Nebuchadnezzar.', 60, 70, 90, 60, 10, 85, 90),
  ('maximus', 'Maximus', 'movie', 'epic', 'Gladiator.', 90, 65, 70, 85, 10, 95, 140),
  ('jack_sparrow', 'Jack Sparrow', 'movie', 'common', 'Pirate lord of the Caribbean.', 50, 70, 80, 55, 10, 80, 70),
];

class CharacterRepository {
  CharacterRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── In-memory catalog (always available) ──────────────────────────────────

  static final List<Character> _local = _catalog.map((t) {
    final (id, name, universe, rarity, desc, str, spd, intel, dur, en, fight, price) = t;
    return Character(
      id: id,
      name: name,
      universe: universeFromString(universe),
      rarity: rarityFromString(rarity),
      description: desc,
      stats: CharacterStats(
        strength: str,
        speed: spd,
        intelligence: intel,
        durability: dur,
        energy: en,
        fightingSkill: fight,
      ),
      basePrice: price,
    );
  }).toList();

  List<Character> fetchAllLocal() => List.unmodifiable(_local);

  Character? fetchByIdLocal(String id) {
    try {
      return _local.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Character> searchLocal(String query) {
    if (query.isEmpty) return fetchAllLocal();
    final q = query.toLowerCase();
    return _local
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.universe.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Firestore (used when characters are customised in the admin panel) ──

  Stream<List<Character>> streamAll() {
    return _db.collection('characters').snapshots().map(
          (snap) => snap.docs
              .map((d) => Character.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<Character?> streamById(String id) {
    return _db
        .collection('characters')
        .doc(id)
        .snapshots()
        .map((s) => s.exists ? Character.fromMap(s.id, s.data()!) : null);
  }
}
