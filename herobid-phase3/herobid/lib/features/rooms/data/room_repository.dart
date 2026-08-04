import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/models/room.dart';
import '../../domain/models/room_player.dart';

class RoomFailure implements Exception {
  final String message;
  const RoomFailure(this.message);
  @override
  String toString() => message;
}

class RoomRepository {
  RoomRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<Room?> listenRoom(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((s) => s.exists ? Room.fromMap(s.id, s.data()!) : null);
  }

  Stream<List<RoomPlayer>> listenPlayers(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RoomPlayer.fromMap(d.id, d.data()))
            .toList());
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Creates a room via the `createRoom` Cloud Function.
  /// Returns the newly created room's ID and code.
  Future<Map<String, String>> createRoom({
    required int budget,
    required int maxPlayers,
    required List<String> characterPool,
  }) async {
    try {
      final result = await _functions.httpsCallable('createRoom').call({
        'budget': budget,
        'maxPlayers': maxPlayers,
        'characterPool': characterPool,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return {
        'roomId': data['roomId'] as String,
        'code': data['code'] as String,
      };
    } on FirebaseFunctionsException catch (e) {
      throw RoomFailure(e.message ?? 'Failed to create room.');
    }
  }

  /// Joins a room via the `joinRoom` Cloud Function.
  /// Returns the roomId.
  Future<String> joinRoom(String code) async {
    try {
      final result = await _functions
          .httpsCallable('joinRoom')
          .call({'code': code.toUpperCase()});
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['roomId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw RoomFailure(e.message ?? 'Failed to join room.');
    }
  }

  Future<void> setReady({
    required String roomId,
    required String uid,
    required bool ready,
  }) async {
    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(uid)
        .update({'isReady': ready});
  }

  Future<void> startAuction(String roomId) async {
    try {
      await _functions
          .httpsCallable('startAuction')
          .call({'roomId': roomId});
    } on FirebaseFunctionsException catch (e) {
      throw RoomFailure(e.message ?? 'Failed to start auction.');
    }
  }

  Future<void> leaveRoom({
    required String roomId,
    required String uid,
  }) async {
    final batch = _db.batch();
    final roomRef = _db.collection('rooms').doc(roomId);
    final playerRef = roomRef.collection('players').doc(uid);
    batch.delete(playerRef);
    batch.update(roomRef, {
      'playerIds': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }
}
