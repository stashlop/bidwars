import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status progression for a room:
/// lobby → auction → teamBuilder → battle → done
enum RoomStatus { lobby, auction, teamBuilder, battle, done }

RoomStatus roomStatusFromString(String s) {
  switch (s) {
    case 'auction':
      return RoomStatus.auction;
    case 'teamBuilder':
      return RoomStatus.teamBuilder;
    case 'battle':
      return RoomStatus.battle;
    case 'done':
      return RoomStatus.done;
    default:
      return RoomStatus.lobby;
  }
}

String roomStatusToString(RoomStatus s) => s.name;

class Room extends Equatable {
  final String id;
  final String code;
  final String hostUid;
  final RoomStatus status;
  final int maxPlayers;
  final int budget;
  final List<String> characterPool;
  final List<String> playerIds;
  final int currentCharacterIndex;
  final DateTime? createdAt;

  const Room({
    required this.id,
    required this.code,
    required this.hostUid,
    required this.status,
    required this.maxPlayers,
    required this.budget,
    required this.characterPool,
    required this.playerIds,
    this.currentCharacterIndex = 0,
    this.createdAt,
  });

  bool get isLobby => status == RoomStatus.lobby;
  bool get isAuction => status == RoomStatus.auction;
  bool get isFull => playerIds.length >= maxPlayers;

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    return Room(
      id: id,
      code: map['code'] as String? ?? '',
      hostUid: map['hostUid'] as String? ?? '',
      status: roomStatusFromString(map['status'] as String? ?? 'lobby'),
      maxPlayers: (map['maxPlayers'] as num?)?.toInt() ?? 8,
      budget: (map['budget'] as num?)?.toInt() ?? 1000,
      characterPool: List<String>.from(map['characterPool'] as List? ?? []),
      playerIds: List<String>.from(map['playerIds'] as List? ?? []),
      currentCharacterIndex:
          (map['currentCharacterIndex'] as num?)?.toInt() ?? 0,
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'hostUid': hostUid,
        'status': roomStatusToString(status),
        'maxPlayers': maxPlayers,
        'budget': budget,
        'characterPool': characterPool,
        'playerIds': playerIds,
        'currentCharacterIndex': currentCharacterIndex,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props => [
        id,
        code,
        hostUid,
        status,
        maxPlayers,
        budget,
        characterPool,
        playerIds,
        currentCharacterIndex,
        createdAt,
      ];
}
