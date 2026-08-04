import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Mirrors the profile document created server-side by the
/// `onUserCreate` Cloud Function (functions/src/index.ts). Every field
/// here has a matching key in that trigger, so a freshly-signed-up user
/// round-trips cleanly the moment their doc lands.
class AppUser extends Equatable {
  final String uid;
  final String username;
  final String? avatarUrl;
  final String? email;
  final int coins;
  final int xp;
  final int wins;
  final int losses;
  final int charactersOwned;
  final String? favouriteCharacterId;
  final String currentRank;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.username,
    this.avatarUrl,
    this.email,
    this.coins = 1000,
    this.xp = 0,
    this.wins = 0,
    this.losses = 0,
    this.charactersOwned = 0,
    this.favouriteCharacterId,
    this.currentRank = 'Unranked',
    this.createdAt,
  });

  /// 0 with no matches played, otherwise wins / (wins + losses).
  double get winRate {
    final played = wins + losses;
    if (played == 0) return 0;
    return wins / played;
  }

  AppUser copyWith({
    String? username,
    String? avatarUrl,
    String? email,
    int? coins,
    int? xp,
    int? wins,
    int? losses,
    int? charactersOwned,
    String? favouriteCharacterId,
    String? currentRank,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      charactersOwned: charactersOwned ?? this.charactersOwned,
      favouriteCharacterId: favouriteCharacterId ?? this.favouriteCharacterId,
      currentRank: currentRank ?? this.currentRank,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarUrl': avatarUrl,
      'email': email,
      'coins': coins,
      'xp': xp,
      'wins': wins,
      'losses': losses,
      'charactersOwned': charactersOwned,
      'favouriteCharacterId': favouriteCharacterId,
      'currentRank': currentRank,
      'createdAt': createdAt,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    return AppUser(
      uid: uid,
      username: map['username'] as String? ?? 'Hero',
      avatarUrl: map['avatarUrl'] as String?,
      email: map['email'] as String?,
      coins: (map['coins'] as num?)?.toInt() ?? 1000,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      charactersOwned: (map['charactersOwned'] as num?)?.toInt() ?? 0,
      favouriteCharacterId: map['favouriteCharacterId'] as String?,
      currentRank: map['currentRank'] as String? ?? 'Unranked',
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        username,
        avatarUrl,
        email,
        coins,
        xp,
        wins,
        losses,
        charactersOwned,
        favouriteCharacterId,
        currentRank,
        createdAt,
      ];
}
