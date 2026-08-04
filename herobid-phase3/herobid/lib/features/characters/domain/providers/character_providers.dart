import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/character_repository.dart';
import '../models/character.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final characterRepositoryProvider =
    Provider<CharacterRepository>((_) => CharacterRepository());

// ── Local catalog providers ───────────────────────────────────────────────────

/// All characters from the local catalog.
final allCharactersProvider = Provider<List<Character>>((ref) {
  return ref.watch(characterRepositoryProvider).fetchAllLocal();
});

/// Single character by id from local catalog.
final characterByIdProvider =
    Provider.family<Character?, String>((ref, id) {
  return ref.watch(characterRepositoryProvider).fetchByIdLocal(id);
});

// ── Search ────────────────────────────────────────────────────────────────────

final characterSearchQueryProvider = StateProvider<String>((_) => '');

final characterSearchProvider = Provider<List<Character>>((ref) {
  final query = ref.watch(characterSearchQueryProvider);
  return ref.watch(characterRepositoryProvider).searchLocal(query);
});

// ── Firestore stream (optional, for admin overrides) ─────────────────────────

final allCharactersStreamProvider = StreamProvider<List<Character>>((ref) {
  return ref.watch(characterRepositoryProvider).streamAll();
});
