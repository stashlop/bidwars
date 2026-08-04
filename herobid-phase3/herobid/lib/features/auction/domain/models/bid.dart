import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Bid extends Equatable {
  final String uid;
  final String username;
  final int amount;
  final DateTime placedAt;

  const Bid({
    required this.uid,
    required this.username,
    required this.amount,
    required this.placedAt,
  });

  factory Bid.fromMap(Map<String, dynamic> map) {
    final rawPlacedAt = map['placedAt'];
    return Bid(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? 'Hero',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      placedAt: rawPlacedAt is Timestamp
          ? rawPlacedAt.toDate()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [uid, amount, placedAt];
}
