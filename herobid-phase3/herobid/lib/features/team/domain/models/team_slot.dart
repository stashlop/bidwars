import 'package:equatable/equatable.dart';

class TeamSlot extends Equatable {
  final int position; // 0–4
  final String? characterId;
  final String? characterName;

  const TeamSlot({
    required this.position,
    this.characterId,
    this.characterName,
  });

  bool get isEmpty => characterId == null;

  TeamSlot copyWith({String? characterId, String? characterName}) => TeamSlot(
        position: position,
        characterId: characterId ?? this.characterId,
        characterName: characterName ?? this.characterName,
      );

  factory TeamSlot.fromMap(Map<String, dynamic> map) => TeamSlot(
        position: (map['position'] as num?)?.toInt() ?? 0,
        characterId: map['characterId'] as String?,
        characterName: map['characterName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'position': position,
        'characterId': characterId,
        'characterName': characterName,
      };

  @override
  List<Object?> get props => [position, characterId, characterName];
}
