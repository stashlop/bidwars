import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/room_repository.dart';
import '../models/room.dart';
import '../models/room_player.dart';

// ── Repository ───────────────────────────────────────────────────────────────

final roomRepositoryProvider = Provider<RoomRepository>((_) => RoomRepository());

// ── Live room stream ─────────────────────────────────────────────────────────

/// Streams the room document for [roomId].
final roomProvider =
    StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).listenRoom(roomId);
});

/// Streams the players subcollection for [roomId].
final roomPlayersProvider =
    StreamProvider.family<List<RoomPlayer>, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).listenPlayers(roomId);
});

// ── Active room ID ────────────────────────────────────────────────────────────

/// Set by the router / controller when a room is created or joined.
final activeRoomIdProvider = StateProvider<String?>((ref) => null);

// ── Room controller ───────────────────────────────────────────────────────────

class RoomController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Map<String, String>> createRoom({
    required int budget,
    required int maxPlayers,
    required List<String> characterPool,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(roomRepositoryProvider).createRoom(
            budget: budget,
            maxPlayers: maxPlayers,
            characterPool: characterPool,
          ),
    );
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (result.hasError) throw result.error!;
    return result.value!;
  }

  Future<String> joinRoom(String code) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(roomRepositoryProvider).joinRoom(code),
    );
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (result.hasError) throw result.error!;
    return result.value!;
  }

  Future<void> setReady({
    required String roomId,
    required String uid,
    required bool ready,
  }) async {
    await ref.read(roomRepositoryProvider).setReady(
          roomId: roomId,
          uid: uid,
          ready: ready,
        );
  }

  Future<void> startAuction(String roomId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(roomRepositoryProvider).startAuction(roomId),
    );
  }

  Future<void> leaveRoom({required String roomId, required String uid}) async {
    await ref
        .read(roomRepositoryProvider)
        .leaveRoom(roomId: roomId, uid: uid);
  }
}

final roomControllerProvider =
    AsyncNotifierProvider<RoomController, void>(RoomController.new);
