import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Raw Firebase auth state - go_router's redirect logic watches this to
/// decide signed-in vs signed-out, nothing more.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in player's Firestore profile, i.e. the document
/// `onUserCreate` bootstraps. Null while signed out or while that
/// document hasn't landed yet (there's a brief window right after
/// sign-up before the Cloud Function trigger finishes writing it).
final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Drives the sign-in / sign-up screens. Holds nothing but loading +
/// error state - the actual session lives in Firebase and is read back
/// through [authStateChangesProvider], so there's no state to duplicate
/// here on success.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithApple(),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            username: username,
          ),
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(email),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
