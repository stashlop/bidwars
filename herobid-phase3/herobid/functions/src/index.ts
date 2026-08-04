import * as admin from "firebase-admin";
import { auth } from "firebase-functions/v1";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();

/**
 * Bootstraps a Firestore user profile whenever a new Firebase Auth
 * account is created. Google, Apple, and Email sign-in (Phase 3) all
 * create a Firebase Auth user the same way, so this one trigger covers
 * every login method.
 */
export const onUserCreate = auth.user().onCreate(async (user) => {
  const profile = {
    uid: user.uid,
    username: user.displayName ?? `Hero${user.uid.substring(0, 6)}`,
    avatarUrl: user.photoURL ?? null,
    email: user.email ?? null,
    coins: 1000,
    xp: 0,
    wins: 0,
    losses: 0,
    charactersOwned: 0,
    favouriteCharacterId: null,
    currentRank: "Unranked",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("users").doc(user.uid).set(profile, { merge: true });
});

/**
 * Placeholder - implemented in Phase 5 (Rooms).
 * Will validate the room config, generate a unique room code, and
 * create the room doc + host's player subdocument atomically.
 */
export const createRoom = onCall(async () => {
  throw new HttpsError("unimplemented", "createRoom lands in Phase 5.");
});

/**
 * Placeholder - implemented in Phase 6 (Live Auction).
 * This will be the ONLY code path allowed to write a bid. It runs
 * inside a Firestore transaction so two simultaneous bids can never
 * both "win" - that's what firestore.rules and database.rules.json
 * are both already locking down in anticipation of this.
 */
export const placeBid = onCall(async () => {
  throw new HttpsError("unimplemented", "placeBid lands in Phase 6.");
});

/**
 * Placeholder - implemented in Phase 8 (Battle Engine).
 */
export const runBattle = onCall(async () => {
  throw new HttpsError("unimplemented", "runBattle lands in Phase 8.");
});
