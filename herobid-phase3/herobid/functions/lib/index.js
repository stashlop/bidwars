"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.lockTeam = exports.startAuction = exports.joinRoom = exports.runBattle = exports.placeBid = exports.testCreateRoom = exports.createRoom = exports.onUserCreate = void 0;
const admin = require("firebase-admin");
const v1_1 = require("firebase-functions/v1");
const https_1 = require("firebase-functions/v2/https");
admin.initializeApp();
const db = admin.firestore();
/**
 * Bootstraps a Firestore user profile whenever a new Firebase Auth
 * account is created. Google, Apple, and Email sign-in (Phase 3) all
 * create a Firebase Auth user the same way, so this one trigger covers
 * every login method.
 */
exports.onUserCreate = v1_1.auth.user().onCreate(async (user) => {
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
exports.createRoom = (0, https_1.onCall)(async (req) => {
    const data = req.data ?? {};
    const auth = req.auth;
    if (!auth || !auth.uid) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    return await createRoomImpl(auth.uid, data);
});
// Internal implementation so we can reuse in tests/emulator
async function createRoomImpl(hostUid, data) {
    const budget = Number(data.budget ?? 1000);
    const maxPlayers = Number(data.maxPlayers ?? 8);
    const characterPool = Array.isArray(data.characterPool)
        ? data.characterPool.map(String)
        : [];
    if (!characterPool || characterPool.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "characterPool required.");
    }
    // Generate a unique 6-char room code
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const genCode = () => Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    // Try to ensure uniqueness
    let code = genCode();
    for (let i = 0; i < 8; i++) {
        const snap = await db.collection('rooms').where('code', '==', code).limit(1).get();
        if (snap.empty)
            break;
        code = genCode();
    }
    // Create room + player subdoc atomically
    const roomRef = db.collection('rooms').doc();
    const playerRef = roomRef.collection('players').doc(hostUid);
    const userDoc = await db.collection('users').doc(hostUid).get();
    const username = userDoc.exists ? userDoc.data().username : `Hero${hostUid.substring(0, 6)}`;
    const avatarUrl = userDoc.exists ? userDoc.data().avatarUrl : null;
    const coins = userDoc.exists ? userDoc.data().coins ?? 1000 : 1000;
    await db.runTransaction(async (tx) => {
        tx.set(roomRef, {
            code,
            hostUid,
            status: 'lobby',
            maxPlayers,
            budget,
            characterPool,
            playerIds: [hostUid],
            currentCharacterIndex: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.set(playerRef, {
            username,
            avatarUrl,
            coins,
            isHost: true,
            isReady: false,
            wonCharacterIds: [],
        });
    });
    return { roomId: roomRef.id, code };
}
// Emulator-only test endpoint to create a room as a given uid (POST JSON {uid, data})
exports.testCreateRoom = (0, https_1.onRequest)((req, res) => {
    if (!process.env.FUNCTIONS_EMULATOR) {
        res.status(403).send('Forbidden');
        return;
    }
    const body = req.method === 'GET' ? req.query : req.body || {};
    const uid = String(body.uid ?? '');
    const data = body.data ?? {};
    if (!uid) {
        res.status(400).json({ error: 'uid required' });
        return;
    }
    createRoomImpl(uid, data)
        .then((result) => {
        res.json(result);
    })
        .catch((err) => {
        console.error('testCreateRoom error', err);
        const message = err?.message || String(err);
        res.status(500).json({ error: message });
    });
});
/**
 * Placeholder - implemented in Phase 6 (Live Auction).
 * This will be the ONLY code path allowed to write a bid. It runs
 * inside a Firestore transaction so two simultaneous bids can never
 * both "win" - that's what firestore.rules and database.rules.json
 * are both already locking down in anticipation of this.
 */
exports.placeBid = (0, https_1.onCall)(async () => {
    throw new https_1.HttpsError("unimplemented", "placeBid lands in Phase 6.");
});
/**
 * Placeholder - implemented in Phase 8 (Battle Engine).
 */
exports.runBattle = (0, https_1.onCall)(async () => {
    throw new https_1.HttpsError("unimplemented", "runBattle lands in Phase 8.");
});
// ------------------------- Phase 5/6/7 helpers ------------------------------
exports.joinRoom = (0, https_1.onCall)(async (req) => {
    const data = req.data ?? {};
    const auth = req.auth;
    if (!auth || !auth.uid)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required.');
    const code = String((data.code ?? '')).toUpperCase();
    if (code.length < 3)
        throw new https_1.HttpsError('invalid-argument', 'Invalid code.');
    // Find room by code
    const roomSnap = await db.collection('rooms').where('code', '==', code).limit(1).get();
    if (roomSnap.empty)
        throw new https_1.HttpsError('not-found', 'Room not found.');
    const roomDoc = roomSnap.docs[0];
    const roomRef = roomDoc.ref;
    // Check capacity and atomically add player
    const userUid = auth.uid;
    const userDoc = await db.collection('users').doc(userUid).get();
    const username = userDoc.exists ? userDoc.data().username : `Hero${userUid.substring(0, 6)}`;
    const avatarUrl = userDoc.exists ? userDoc.data().avatarUrl : null;
    const coins = userDoc.exists ? userDoc.data().coins ?? 1000 : 1000;
    await db.runTransaction(async (tx) => {
        const fresh = await tx.get(roomRef);
        if (!fresh.exists)
            throw new https_1.HttpsError('not-found', 'Room not found.');
        const data = fresh.data();
        const playerIds = data.playerIds ?? [];
        const maxPlayers = data.maxPlayers ?? 8;
        if (playerIds.includes(userUid))
            return; // already joined
        if (playerIds.length >= maxPlayers)
            throw new https_1.HttpsError('resource-exhausted', 'Room is full.');
        tx.update(roomRef, { playerIds: admin.firestore.FieldValue.arrayUnion(userUid) });
        const playerRef = roomRef.collection('players').doc(userUid);
        tx.set(playerRef, {
            username,
            avatarUrl,
            coins,
            isHost: false,
            isReady: false,
            wonCharacterIds: [],
        });
    });
    return { roomId: roomRef.id };
});
exports.startAuction = (0, https_1.onCall)(async (req) => {
    const data = req.data ?? {};
    const auth = req.auth;
    if (!auth || !auth.uid)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required.');
    const roomId = String(data.roomId ?? '');
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId required.');
    const roomRef = db.collection('rooms').doc(roomId);
    const roomDoc = await roomRef.get();
    if (!roomDoc.exists)
        throw new https_1.HttpsError('not-found', 'Room not found.');
    const room = roomDoc.data();
    if (room.hostUid !== auth.uid)
        throw new https_1.HttpsError('permission-denied', 'Only host may start auction.');
    const characterPool = room.characterPool ?? [];
    if (characterPool.length == 0)
        throw new https_1.HttpsError('failed-precondition', 'No characters to auction.');
    // Prepare the first auction item and flip room status to auction
    await db.runTransaction(async (tx) => {
        tx.update(roomRef, { status: 'auction' });
        const currentRef = roomRef.collection('auctionState').doc('current');
        tx.set(currentRef, {
            characterId: characterPool[0],
            currentBid: 0,
            currentBidderUid: null,
            currentBidderName: null,
            timeLeftMs: 30000,
            status: 'active',
            itemIndex: 0,
            totalItems: characterPool.length,
        });
        // clear any previous bids
        const bidsSnap = await tx.get(roomRef.collection('bids').limit(100).orderBy('placedAt'));
        for (const d of bidsSnap.docs) {
            tx.delete(d.ref);
        }
    });
    return { started: true };
});
exports.lockTeam = (0, https_1.onCall)(async (req) => {
    const data = req.data ?? {};
    const auth = req.auth;
    if (!auth || !auth.uid)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required.');
    const roomId = String(data.roomId ?? '');
    if (!roomId)
        throw new https_1.HttpsError('invalid-argument', 'roomId required.');
    const roomRef = db.collection('rooms').doc(roomId);
    const playerRef = roomRef.collection('players').doc(auth.uid);
    await db.runTransaction(async (tx) => {
        tx.update(playerRef, { teamLocked: true });
        const playersSnap = await tx.get(roomRef.collection('players'));
        const allLocked = playersSnap.docs.every((d) => d.data().teamLocked === true || d.data().isHost === true);
        if (allLocked) {
            tx.update(roomRef, { status: 'battle' });
        }
    });
    return { locked: true };
});
//# sourceMappingURL=index.js.map