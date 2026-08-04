import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/domain/providers/auth_providers.dart';
import '../models/team_slot.dart';

// ── Stream providers ──────────────────────────────────────────────────────────

/// Streams the 5-slot team for the current user in [roomId].
final myTeamProvider =
    StreamProvider.family<List<TeamSlot>, String>((ref, roomId) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('players')
      .doc(uid)
      .collection('team')
      .orderBy('position')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => TeamSlot.fromMap(d.data())).toList());
});

/// Won characters for the current user in [roomId].
final myWonCharactersProvider =
    StreamProvider.family<List<String>, String>((ref, roomId) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('players')
      .doc(uid)
      .snapshots()
      .map((s) {
    if (!s.exists) return <String>[];
    final data = s.data()!;
    return List<String>.from(data['wonCharacterIds'] as List? ?? []);
  });
});

// ── Controller ────────────────────────────────────────────────────────────────

class TeamController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> assignSlot({
    required String roomId,
    required int position,
    required String characterId,
    required String characterName,
  }) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(uid)
        .collection('team')
        .doc('slot_$position')
        .set(TeamSlot(
          position: position,
          characterId: characterId,
          characterName: characterName,
        ).toMap());
  }

  Future<void> clearSlot({required String roomId, required int position}) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(uid)
        .collection('team')
        .doc('slot_$position')
        .delete();
  }

  Future<void> lockTeam(String roomId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseFunctions.instance
          .httpsCallable('lockTeam')
          .call({'roomId': roomId});
    });
  }
}

final teamControllerProvider =
    AsyncNotifierProvider<TeamController, void>(TeamController.new);
