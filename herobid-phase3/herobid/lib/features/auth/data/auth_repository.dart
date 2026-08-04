import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thrown for any auth failure, with a message already safe to show a
/// player (Firebase's raw exception text is too technical / leaky).
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// All sign-in methods funnel into the same Firebase Auth account, which
/// is what lets `onUserCreate` (functions/src/index.ts) bootstrap one
/// Firestore profile no matter which provider a player used.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Player closed the picker - not an error, just cancelled.
        throw const AuthFailure('Sign-in cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only hands over the name on the *first* authorization, and
      // Firebase's User.displayName is otherwise left blank for Apple
      // sign-in - so it has to be applied by hand, once, right here.
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
      if (fullName.isNotEmpty &&
          (userCredential.user?.displayName == null ||
              userCredential.user!.displayName!.isEmpty)) {
        await userCredential.user?.updateDisplayName(fullName);
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('Sign-in cancelled.');
      }
      throw AuthFailure('Apple sign-in failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(username);
      // onUserCreate reads displayName at trigger time; reload so any
      // later client-side read of currentUser also sees it immediately.
      await credential.user?.reload();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(input.codeUnits).toString();
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email already has an account. Try signing in instead.';
      case 'invalid-email':
        return 'That email address doesn\'t look right.';
      case 'weak-password':
        return 'Password needs to be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a bit.';
      case 'network-request-failed':
        return 'No connection - check your internet and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
