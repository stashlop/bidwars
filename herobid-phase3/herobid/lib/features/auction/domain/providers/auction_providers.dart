import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auction_item.dart';
import '../models/bid.dart';

// ── Stream providers ──────────────────────────────────────────────────────────

/// Streams the current auctionState document for [roomId].
final auctionItemProvider =
    StreamProvider.family<AuctionItem?, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('auctionState')
      .doc('current')
      .snapshots()
      .map((s) => s.exists ? AuctionItem.fromMap(s.data()!) : null);
});

/// Streams the last 20 bids for the current auction item in [roomId].
final recentBidsProvider =
    StreamProvider.family<List<Bid>, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('bids')
      .orderBy('placedAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Bid.fromMap(d.data())).toList());
});

// ── Bid controller ────────────────────────────────────────────────────────────

class BidController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> placeBid({
    required String roomId,
    required int amount,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseFunctions.instance.httpsCallable('placeBid').call({
        'roomId': roomId,
        'amount': amount,
      });
    });
  }
}

final bidControllerProvider =
    AsyncNotifierProvider<BidController, void>(BidController.new);
