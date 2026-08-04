import 'package:equatable/equatable.dart';

class RoomPlayer extends Equatable {
  final String uid;
  final String username;
  final String? avatarUrl;
  final int coins;
  final bool isHost;
  final bool isReady;
  final List<String> wonCharacterIds;

  const RoomPlayer({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.coins,
    this.isHost = false,
    this.isReady = false,
    this.wonCharacterIds = const [],
  });

  RoomPlayer copyWith({
    String? username,
    String? avatarUrl,
    int? coins,
    bool? isHost,
    bool? isReady,
    List<String>? wonCharacterIds,
  }) =>
      RoomPlayer(
        uid: uid,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        coins: coins ?? this.coins,
        isHost: isHost ?? this.isHost,
        isReady: isReady ?? this.isReady,
        wonCharacterIds: wonCharacterIds ?? this.wonCharacterIds,
      );

  factory RoomPlayer.fromMap(String uid, Map<String, dynamic> map) =>
      RoomPlayer(
        uid: uid,
        username: map['username'] as String? ?? 'Hero',
        avatarUrl: map['avatarUrl'] as String?,
        coins: (map['coins'] as num?)?.toInt() ?? 1000,
        isHost: map['isHost'] as bool? ?? false,
        isReady: map['isReady'] as bool? ?? false,
        wonCharacterIds:
            List<String>.from(map['wonCharacterIds'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'avatarUrl': avatarUrl,
        'coins': coins,
        'isHost': isHost,
        'isReady': isReady,
        'wonCharacterIds': wonCharacterIds,
      };

  @override
  List<Object?> get props =>
      [uid, username, avatarUrl, coins, isHost, isReady, wonCharacterIds];
}
