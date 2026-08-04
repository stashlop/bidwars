# HeroBid

Real-time multiplayer character-auction game. Players join a room, get a
fixed budget, bid against each other for Marvel / DC / Anime / Movie
characters, build a team, then watch an AI-narrated battle decide the
winner.

## Status

- [x] 1. Folder structure
- [x] 2. Firebase setup (rules, Cloud Functions skeleton, config)
- [x] 3. Authentication (Google / Apple / Email)
- [ ] 4. Home UI
- [ ] 5. Room creation & joining
- [ ] 6. Live auction
- [ ] 7. Team builder
- [ ] 8. Battle engine
- [ ] 9. Character catalog & admin tooling
- [ ] 10. Deployment

## A note on this drop specifically

Only a subset of the original project's files (config files, pubspec,
README, a few Dart/TS files) came into this session — the original
`core/theme`, `core/router`, `core/widgets`, and `features/characters`
files from Phases 1–2 weren't part of what was shared here. To keep
Phase 3 self-contained and runnable, this drop **recreates** minimal,
consistent versions of:

- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/glass_container.dart`, `neon_button.dart`
- `lib/core/router/app_router.dart`

If you still have your originals from the earlier drop, **use those
instead** — everything Phase 3 needs is `Theme.of(context).colorScheme`
and go_router's route table, so your originals should slot back in
without touching any auth code. `test/models_test.dart` still expects a
`Character`/`CharacterStats` model at
`lib/features/characters/domain/models/character.dart` — that file
wasn't part of this session either, so keep your original there.

## Phase 3 - what's actually new

- `AppUser` domain model (`features/auth/domain/models/app_user.dart`),
  matching the shape `onUserCreate` already writes to Firestore
- `AuthRepository` (`features/auth/data/`) - Google, Apple, and
  email/password sign-in, all through Firebase Auth, plus password
  reset and sign-out
- Riverpod providers (`features/auth/domain/providers/auth_providers.dart`):
  raw auth state, the live Firestore profile stream, and an
  `AsyncNotifier` driving the sign-in screens' loading/error state
- Two screens: `SignInScreen` (Google / Apple / "continue with email")
  and `EmailAuthScreen` (sign-in ⇄ sign-up toggle, forgot-password)
- `go_router` now redirects based on live auth state - signed-out users
  land on `/sign-in`, signed-in users on `/`, and it reacts immediately
  to sign-in/sign-out instead of waiting for the next navigation
- A placeholder `HomeScreen` that proves the whole chain works: shows
  the signed-in player's bootstrapped profile (coins, rank) pulled live
  from Firestore

## Getting started

1. `flutter pub get` from the project root (this drop adds one new
   dependency, `crypto`, needed for Apple sign-in's nonce hashing)
2. Create a Firebase project at console.firebase.google.com if you
   haven't already
3. `firebase login`, then `flutterfire configure` from the project root
   - this replaces `lib/firebase_options.dart` with your real
   per-platform keys
4. In the Firebase console: **Authentication → Sign-in method** - enable
   Google, Apple, and Email/Password
5. Apple sign-in additionally needs, in your Apple Developer account: a
   Services ID with "Sign In with Apple" enabled, and (for iOS) the
   capability added in Xcode - that part is portal/Xcode setup, not
   something to generate in code
6. `cd functions && npm install`
7. `firebase deploy --only firestore:rules,database,storage,functions`
8. `flutter run`

## What's verified vs. hand-written

No Flutter/Dart toolchain or network access in this sandbox, so **the
Dart code (Phase 3 included) is carefully hand-written and reviewed,
but not compiled or analyzed.** Run `flutter analyze` and `flutter test`
right after `pub get` and let me know what comes back.

The Cloud Functions side (`functions/`) is unchanged from the previous
drop and wasn't re-verified this session (no network access this time
around) - it was verified in the prior drop.

## Next

Phase 4 (Home UI) whenever you're ready.
MIT License

Copyright (c) 2026 stashlop

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
