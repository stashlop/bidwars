<<<<<<< HEAD
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
# bidwars — HeroBid (Phase 3)

[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/stashlop/bidwars/ci.yml?branch=main&label=ci&logo=github)](https://github.com/stashlop/bidwars/actions)
[![Repository Size](https://img.shields.io/github/repo-size/stashlop/bidwars)](https://github.com/stashlop/bidwars)

Lightweight Phase 3 drop of the HeroBid multiplayer auction game. The Flutter app and companion Cloud Functions live under `herobid-phase3/herobid` and are intended to demonstrate a real-time auction → team builder → AI battle flow powered by Firebase.

Quick links
- App folder: [herobid-phase3/herobid](herobid-phase3/herobid)
- App README (detailed project notes & Firebase setup): [herobid-phase3/herobid/README.md](herobid-phase3/herobid/README.md)

Features
- Real-time auction rooms with Firebase-backed state
- Authentication: Google, Apple, Email/Password
- Team builder and simple battle engine
- Riverpod + go_router app structure

Getting started (development)

1) Install Flutter and enable web support (if you prefer web development).

```bash
# (example, one-time)
git clone https://github.com/flutter/flutter.git --depth 1 ~/flutter
export PATH=~/flutter/bin:$PATH
flutter config --enable-web
```

2) Install project dependencies and run the app (web-server):

```bash
cd herobid-phase3/herobid
flutter pub get
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

3) Firebase: create a Firebase project and configure platforms. See the app README for exact steps.

```bash
# from repo root
cd herobid-phase3/herobid
firebase login
flutterfire configure
```

Development tips
- Run static analysis: `flutter analyze`
- Run tests: `flutter test`
- Hot reload while running: press `r` in the `flutter run` terminal

GitHub / CI
If you want CI, add a GitHub Actions workflow that runs `flutter analyze` and `flutter test` on PRs. I can scaffold this for you if you'd like.

Contributing
- Open issues and PRs against this repository. For code style, follow existing patterns (Riverpod, go_router, and Flutter recommended best practices).

License
- See the repository owner for license and contribution guidelines. If you want an MIT or other license file added, I can create it.

Support
- For running the app locally you need a working Flutter SDK and a Firebase project for full functionality (auth, database, functions).

>>>>>>> ded46e9 (Save local changes)
copies or substantial portions of the Software.
