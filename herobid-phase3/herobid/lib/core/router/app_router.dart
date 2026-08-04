import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// Bridges a Riverpod stream to go_router's `Listenable`-based refresh
/// hook, so a sign-in / sign-out event re-runs `redirect` immediately
/// instead of waiting for the next navigation.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      // Still resolving the very first auth check - don't redirect yet,
      // the splash/loading branch below covers this frame.
      if (!authState.hasValue && !authState.hasError) return null;

      final User? user = authState.valueOrNull;
      final signedIn = user != null;
      final onAuthRoute = state.matchedLocation == '/sign-in';

      if (!signedIn && !onAuthRoute) return '/sign-in';
      if (signedIn && onAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // Every other route from the nav map plugs in here as its phase
      // lands (rooms, auction, team builder, battle, ...).
    ],
  );
});
