import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AuctionItemStatus { pending, active, sold, skipped }

AuctionItemStatus auctionItemStatusFromString(String s) {
  switch (s) {
    case 'active':
      return AuctionItemStatus.active;
    case 'sold':
      return AuctionItemStatus.sold;
    case 'skipped':
      return AuctionItemStatus.skipped;
    default:
      return AuctionItemStatus.pending;
  }
}

class AuctionItem extends Equatable {
  final String characterId;
  final int currentBid;
  final String? currentBidderUid;
  final String? currentBidderName;
  final int timeLeftMs;
  final AuctionItemStatus status;
  final int itemIndex;
  final int totalItems;

  const AuctionItem({
    required this.characterId,
    required this.currentBid,
    this.currentBidderUid,
    this.currentBidderName,
    required this.timeLeftMs,
    required this.status,
    required this.itemIndex,
    required this.totalItems,
  });

  bool get isActive => status == AuctionItemStatus.active;

  factory AuctionItem.fromMap(Map<String, dynamic> map) => AuctionItem(
        characterId: map['characterId'] as String? ?? '',
        currentBid: (map['currentBid'] as num?)?.toInt() ?? 0,
        currentBidderUid: map['currentBidderUid'] as String?,
        currentBidderName: map['currentBidderName'] as String?,
        timeLeftMs: (map['timeLeftMs'] as num?)?.toInt() ?? 0,
        status: auctionItemStatusFromString(
            map['status'] as String? ?? 'pending'),
        itemIndex: (map['itemIndex'] as num?)?.toInt() ?? 0,
        totalItems: (map['totalItems'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [
        characterId,
        currentBid,
        currentBidderUid,
        timeLeftMs,
        status,
        itemIndex,
        totalItems,
      ];
}
